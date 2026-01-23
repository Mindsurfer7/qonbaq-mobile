import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../main.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/customer.dart';
import '../../data/models/order_model.dart';
import '../../data/models/validation_error.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import '../providers/crm_provider.dart';

/// Диалог для создания заказа
class CreateOrderDialog extends StatefulWidget {
  final OrderFunnelStage? initialStage;
  final String? initialCustomerId;

  const CreateOrderDialog({
    super.key,
    this.initialStage,
    this.initialCustomerId,
  });

  @override
  State<CreateOrderDialog> createState() => _CreateOrderDialogState();
}

class _CreateOrderDialogState extends State<CreateOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalAmountController = TextEditingController();

  OrderFunnelStage? _selectedStage;
  Customer? _selectedCustomer;
  DateTime? _paymentDueDate;
  bool _isLoading = false;
  String? _error;
  List<ValidationError>? _validationErrors;
  List<Customer>? _customers;
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage ?? OrderFunnelStage.orderAccepted;
    _loadCustomers();
  }

  @override
  void dispose() {
    _orderNumberController.dispose();
    _descriptionController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) return;

    setState(() {
      _isLoadingCustomers = true;
    });

    // Загружаем всех клиентов из всех стадий
    final allCustomers = <Customer>[];
    for (final stage in SalesFunnelStage.values) {
      final customers = crmProvider.getCustomersByStage(stage);
      allCustomers.addAll(customers);
    }

    // Если клиентов нет в кэше, загружаем их
    if (allCustomers.isEmpty) {
      await crmProvider.loadAllCustomers(businessId);
      // Повторно собираем всех клиентов
      for (final stage in SalesFunnelStage.values) {
        final customers = crmProvider.getCustomersByStage(stage);
        allCustomers.addAll(customers);
      }
    }

    setState(() {
      _customers = allCustomers;
      _isLoadingCustomers = false;

      // Если указан initialCustomerId, выбираем его
      if (widget.initialCustomerId != null && allCustomers.isNotEmpty) {
        try {
          _selectedCustomer = allCustomers.firstWhere(
            (c) => c.id == widget.initialCustomerId,
          );
        } catch (e) {
          // Клиент не найден, оставляем null
        }
      }
    });
  }

  String _getStageTitle(OrderFunnelStage stage) {
    switch (stage) {
      case OrderFunnelStage.orderAccepted:
        return 'Заказ принят';
      case OrderFunnelStage.orderStarted:
        return 'Заказ начат';
      case OrderFunnelStage.orderInProgress:
        return 'Заказ в работе';
      case OrderFunnelStage.orderReady:
        return 'Заказ готов';
      case OrderFunnelStage.orderDelivered:
        return 'Заказ передан клиенту';
      case OrderFunnelStage.orderReturned:
        return 'Возврат по причине';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      setState(() {
        _error = 'Выберите клиента';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _validationErrors = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Бизнес не выбран';
      });
      return;
    }

    // Парсим сумму заказа
    double totalAmount;
    try {
      totalAmount = double.parse(
        _totalAmountController.text.trim().replaceAll(' ', ''),
      );
      if (totalAmount <= 0) {
        throw FormatException('Сумма должна быть больше нуля');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Некорректная сумма заказа';
      });
      return;
    }

    // Создаем модель заказа
    final order = OrderModel(
      id: '', // Будет установлен сервером
      businessId: businessId,
      customerId: _selectedCustomer!.id,
      stage: _selectedStage!,
      orderNumber:
          _orderNumberController.text.trim().isNotEmpty
              ? _orderNumberController.text.trim()
              : null,
      description:
          _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
      totalAmount: totalAmount,
      paidAmount: 0,
      isPaid: false,
      isPartiallyPaid: false,
      isOverdue: false,
      paymentDueDate: _paymentDueDate,
      isBlocked: false,
      movedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await crmProvider.createOrderForBusiness(
      order.toEntity(),
      businessId,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          if (failure is ValidationFailure) {
            _validationErrors = failure.errors;
            _error = failure.serverMessage ?? failure.message;
          } else {
            _error = failure.message;
          }
        });
      },
      (createdOrder) {
        // Успешно создан - закрываем диалог и обновляем список
        Navigator.of(context).pop();
        // Обновляем список заказов для соответствующего статуса
        crmProvider.refreshOrdersStage(businessId, createdOrder.stage);
      },
    );
  }

  String? _getFieldError(String fieldName) {
    if (_validationErrors == null) return null;
    final error = _validationErrors!.firstWhere(
      (e) => e.field == fieldName,
      orElse: () => ValidationError(field: '', message: '', code: ''),
    );
    return error.message.isNotEmpty ? error.message : null;
  }

  Future<void> _selectPaymentDueDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 1, 12, 31);

    // Используем контекст из корневого MaterialApp для доступа к MaterialLocalizations
    final rootContext = navigatorKey.currentContext;
    if (rootContext == null) return;

    final picked = await showDatePicker(
      context: rootContext,
      initialDate: _paymentDueDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('ru', 'RU'),
    );

    if (picked != null) {
      setState(() {
        _paymentDueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Создать заказ'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Выбор клиента
              DropdownButtonFormField<Customer>(
                value: _selectedCustomer,
                decoration: InputDecoration(
                  labelText: 'Клиент *',
                  border: const OutlineInputBorder(),
                  errorText: _getFieldError('customerId'),
                  errorMaxLines: 2,
                ),
                items:
                    _customers?.map((customer) {
                      final displayName =
                          customer.displayName ??
                          customer.name ??
                          'Клиент #${customer.id.substring(0, 8)}';
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(
                          displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged:
                    _isLoading || _isLoadingCustomers
                        ? null
                        : (value) {
                          setState(() {
                            _selectedCustomer = value;
                          });
                        },
                validator: (value) {
                  if (value == null) {
                    return 'Выберите клиента';
                  }
                  return null;
                },
              ),
              if (_isLoadingCustomers) ...[
                const SizedBox(height: 8),
                const Center(child: CircularProgressIndicator()),
              ],
              const SizedBox(height: 16),

              // Номер заказа
              TextFormField(
                controller: _orderNumberController,
                decoration: InputDecoration(
                  labelText: 'Номер заказа',
                  hintText: 'Необязательно',
                  border: const OutlineInputBorder(),
                  errorText: _getFieldError('orderNumber'),
                  errorMaxLines: 2,
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Необязательно',
                  border: const OutlineInputBorder(),
                  errorText: _getFieldError('description'),
                  errorMaxLines: 2,
                ),
                maxLines: 3,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Сумма заказа
              TextFormField(
                controller: _totalAmountController,
                decoration: InputDecoration(
                  labelText: 'Сумма заказа *',
                  hintText: 'Например: 100000',
                  border: const OutlineInputBorder(),
                  errorText: _getFieldError('totalAmount'),
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Сумма заказа обязательна';
                  }
                  try {
                    final amount = double.parse(
                      value.trim().replaceAll(' ', ''),
                    );
                    if (amount <= 0) {
                      return 'Сумма должна быть больше нуля';
                    }
                  } catch (e) {
                    return 'Некорректная сумма';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Дата оплаты
              InkWell(
                onTap: _isLoading ? null : _selectPaymentDueDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Дата оплаты',
                    hintText: 'Необязательно',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                    errorText: _getFieldError('paymentDueDate'),
                    errorMaxLines: 2,
                  ),
                  child: Text(
                    _paymentDueDate != null
                        ? DateFormat(
                          'dd.MM.yyyy',
                          'ru_RU',
                        ).format(_paymentDueDate!)
                        : 'Выберите дату',
                    style: TextStyle(
                      color:
                          _paymentDueDate != null
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Стадия воронки заказов
              DropdownButtonFormField<OrderFunnelStage>(
                value: _selectedStage,
                decoration: const InputDecoration(
                  labelText: 'Стадия воронки заказов',
                  border: OutlineInputBorder(),
                ),
                items:
                    OrderFunnelStage.values.map((stage) {
                      return DropdownMenuItem(
                        value: stage,
                        child: Text(_getStageTitle(stage)),
                      );
                    }).toList(),
                onChanged:
                    _isLoading
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedStage = value;
                            });
                          }
                        },
              ),

              // Общая ошибка
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSubmit,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Создать'),
        ),
      ],
    );
  }
}
