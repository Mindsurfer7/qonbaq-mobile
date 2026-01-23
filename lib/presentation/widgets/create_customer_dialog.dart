import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/validation_error.dart';
import '../../core/error/failures.dart';
import '../providers/crm_provider.dart';
import '../providers/profile_provider.dart';

/// Диалог для создания клиента
class CreateCustomerDialog extends StatefulWidget {
  final SalesFunnelStage? initialStage;

  const CreateCustomerDialog({
    super.key,
    this.initialStage,
  });

  @override
  State<CreateCustomerDialog> createState() => _CreateCustomerDialogState();
}

class _CreateCustomerDialogState extends State<CreateCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _patronymicController = TextEditingController();
  final _binController = TextEditingController();
  final _iinController = TextEditingController();
  final _commentController = TextEditingController();

  CustomerType _customerType = CustomerType.legalEntity;
  SalesFunnelStage? _selectedStage;
  bool _isLoading = false;
  String? _error;
  List<ValidationError>? _validationErrors;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage ?? SalesFunnelStage.unprocessed;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _patronymicController.dispose();
    _binController.dispose();
    _iinController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getStageTitle(SalesFunnelStage stage) {
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return 'Необработанные';
      case SalesFunnelStage.inProgress:
        return 'В работе';
      case SalesFunnelStage.interested:
        return 'Заинтересованы';
      case SalesFunnelStage.contractSigned:
        return 'Заключен договор';
      case SalesFunnelStage.salesByContract:
        return 'Продажи по договору';
      case SalesFunnelStage.refused:
        return 'Отказ по причине';
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _validationErrors = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final crmProvider = Provider.of<CrmProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Бизнес не выбран';
      });
      return;
    }

    // Создаем модель клиента
    final customer = CustomerModel(
      id: '', // Будет установлен сервером
      businessId: businessId,
      customerType: _customerType,
      displayName: _customerType == CustomerType.legalEntity
          ? (_displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : _nameController.text.trim())
          : _getIndividualName(),
      name: _customerType == CustomerType.legalEntity
          ? _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null
          : null,
      firstName: _customerType == CustomerType.individual
          ? _firstNameController.text.trim().isNotEmpty
              ? _firstNameController.text.trim()
              : null
          : null,
      lastName: _customerType == CustomerType.individual
          ? _lastNameController.text.trim().isNotEmpty
              ? _lastNameController.text.trim()
              : null
          : null,
      patronymic: _customerType == CustomerType.individual
          ? _patronymicController.text.trim().isNotEmpty
              ? _patronymicController.text.trim()
              : null
          : null,
      bin: _customerType == CustomerType.legalEntity
          ? _binController.text.trim().isNotEmpty
              ? _binController.text.trim()
              : null
          : null,
      iin: _customerType == CustomerType.individual
          ? _iinController.text.trim().isNotEmpty
              ? _iinController.text.trim()
              : null
          : null,
      salesFunnelStage: _selectedStage,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await crmProvider.createCustomerForBusiness(customer, businessId);

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
      (createdCustomer) {
        // Успешно создан - закрываем диалог и обновляем список
        Navigator.of(context).pop();
        // Обновляем список клиентов для соответствующего статуса
        crmProvider.refreshStage(businessId, createdCustomer.salesFunnelStage ?? SalesFunnelStage.unprocessed);
      },
    );
  }

  String _getIndividualName() {
    final parts = <String>[];
    if (_lastNameController.text.trim().isNotEmpty) {
      parts.add(_lastNameController.text.trim());
    }
    if (_firstNameController.text.trim().isNotEmpty) {
      parts.add(_firstNameController.text.trim());
    }
    if (_patronymicController.text.trim().isNotEmpty) {
      parts.add(_patronymicController.text.trim());
    }
    return parts.isEmpty ? '' : parts.join(' ');
  }

  String? _getFieldError(String fieldName) {
    if (_validationErrors == null) return null;
    final error = _validationErrors!.firstWhere(
      (e) => e.field == fieldName,
      orElse: () => ValidationError(field: '', message: '', code: ''),
    );
    return error.message.isNotEmpty ? error.message : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Создать клиента'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Тип клиента
              DropdownButtonFormField<CustomerType>(
                value: _customerType,
                decoration: const InputDecoration(
                  labelText: 'Тип клиента *',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CustomerType.legalEntity,
                    child: Text('Юридическое лицо'),
                  ),
                  DropdownMenuItem(
                    value: CustomerType.individual,
                    child: Text('Физическое лицо'),
                  ),
                ],
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _customerType = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Поля для юридического лица
              if (_customerType == CustomerType.legalEntity) ...[
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Название *',
                    hintText: 'Например: ООО "Компания"',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('displayName'),
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Название обязательно';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Краткое название',
                    hintText: 'Необязательно',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('name'),
                    errorMaxLines: 2,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _binController,
                  decoration: InputDecoration(
                    labelText: 'БИН',
                    hintText: 'Необязательно',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('bin'),
                    errorMaxLines: 2,
                  ),
                  enabled: !_isLoading,
                ),
              ],

              // Поля для физического лица
              if (_customerType == CustomerType.individual) ...[
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Фамилия *',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('lastName'),
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Фамилия обязательна';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Имя *',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('firstName'),
                    errorMaxLines: 2,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Имя обязательно';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _patronymicController,
                  decoration: InputDecoration(
                    labelText: 'Отчество',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('patronymic'),
                    errorMaxLines: 2,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _iinController,
                  decoration: InputDecoration(
                    labelText: 'ИИН',
                    hintText: 'Необязательно',
                    border: const OutlineInputBorder(),
                    errorText: _getFieldError('iin'),
                    errorMaxLines: 2,
                  ),
                  enabled: !_isLoading,
                ),
              ],

              const SizedBox(height: 16),

              // Статус воронки продаж
              DropdownButtonFormField<SalesFunnelStage>(
                value: _selectedStage,
                decoration: const InputDecoration(
                  labelText: 'Статус воронки продаж',
                  border: OutlineInputBorder(),
                ),
                items: SalesFunnelStage.values.map((stage) {
                  return DropdownMenuItem(
                    value: stage,
                    child: Text(_getStageTitle(stage)),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStage = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Комментарий
              TextFormField(
                controller: _commentController,
                decoration: InputDecoration(
                  labelText: 'Комментарий',
                  hintText: 'Необязательно',
                  border: const OutlineInputBorder(),
                  errorText: _getFieldError('comment'),
                  errorMaxLines: 2,
                ),
                maxLines: 3,
                enabled: !_isLoading,
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
          child: _isLoading
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
