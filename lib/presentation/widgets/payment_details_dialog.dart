import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/fill_payment_details.dart';
import '../../domain/usecases/get_accounts.dart';
import '../../domain/usecases/get_payment_details_schema.dart';
import '../../core/error/failures.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/profile_provider.dart';
import 'dynamic_block_form.dart';

/// Диалог для заполнения платежных реквизитов
class PaymentDetailsDialog extends StatefulWidget {
  final String approvalId; // ID согласования
  final Approval? approval; // Опционально для обратной совместимости
  final VoidCallback? onSuccess;

  PaymentDetailsDialog({
    super.key,
    String? approvalId,
    this.approval,
    this.onSuccess,
  }) : approvalId = approvalId ?? approval?.id ?? '';

  @override
  State<PaymentDetailsDialog> createState() => _PaymentDetailsDialogState();
}

class _PaymentDetailsDialogState extends State<PaymentDetailsDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  bool _isLoadingSchema = false;
  String? _error;
  
  String? _selectedPaymentMethod; // "CASH" | "BANK_TRANSFER" | "TERMINAL"
  String? _selectedAccountId; // Для CASH
  String? _selectedFromAccountId; // Для BANK_TRANSFER/TERMINAL
  
  List<Account> _cashAccounts = []; // Кассы для CASH
  List<Account> _bankAccounts = []; // Банковские счета для BANK_TRANSFER/TERMINAL
  
  Map<String, dynamic>? _formSchema; // Схема динамической формы
  Map<String, dynamic>? _initialValues; // Начальные значения для формы

  @override
  void initState() {
    super.initState();
    // Предзаполняем поля из formData, если они уже есть (для обратной совместимости)
    if (widget.approval?.formData != null) {
      _selectedPaymentMethod = widget.approval!.formData!['paymentMethod']?.toString();
      _selectedAccountId = widget.approval!.formData!['accountId']?.toString();
      _selectedFromAccountId = widget.approval!.formData!['fromAccountId']?.toString();
      // Сохраняем formData как начальные значения для динамической формы
      _initialValues = Map<String, dynamic>.from(widget.approval!.formData!);
    }
    _loadSchema();
    _loadAccounts();
  }

  Future<void> _loadSchema() async {
    setState(() {
      _isLoadingSchema = true;
      _error = null;
    });

    final getSchemaUseCase = Provider.of<GetPaymentDetailsSchema>(
      context,
      listen: false,
    );

    final result = await getSchemaUseCase.call(widget.approvalId);

    if (!mounted) return;

    result.fold(
      (failure) {
        // Если схема не найдена или ошибка - используем старую форму
        setState(() {
          _isLoadingSchema = false;
          _formSchema = null;
        });
      },
      (schema) {
        setState(() {
          _isLoadingSchema = false;
          _formSchema = schema;
        });
      },
    );
  }

  Future<void> _loadAccounts() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    
    if (selectedBusiness == null) return;

    setState(() {
      _isLoadingAccounts = true;
    });

    final getAccountsUseCase = Provider.of<GetAccounts>(context, listen: false);

    // Загружаем кассы (CASH)
    final cashResult = await getAccountsUseCase.call(
      GetAccountsParams(
        businessId: selectedBusiness.id,
        accountType: 'CASH',
      ),
    );

    // Загружаем банковские счета (BANK_ACCOUNT)
    final bankResult = await getAccountsUseCase.call(
      GetAccountsParams(
        businessId: selectedBusiness.id,
        accountType: 'BANK_ACCOUNT',
      ),
    );

    if (!mounted) return;

    cashResult.fold(
      (failure) {
        // Игнорируем ошибки загрузки касс
      },
      (accounts) {
        setState(() {
          _cashAccounts = accounts.where((a) => a.isActive).toList();
        });
      },
    );

    bankResult.fold(
      (failure) {
        // Игнорируем ошибки загрузки банковских счетов
      },
      (accounts) {
        setState(() {
          _bankAccounts = accounts.where((a) => a.isActive).toList();
        });
      },
    );

    setState(() {
      _isLoadingAccounts = false;
    });
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState == null) {
      setState(() {
        _error = 'Ошибка формы';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Сохраняем значения формы
    _formKey.currentState!.save();
    final formValues = _formKey.currentState!.value;

    // Извлекаем paymentMethod из формы (может быть в динамической форме или в старом формате)
    String? paymentMethod = formValues['paymentMethod'] as String?;
    if (paymentMethod == null) {
      paymentMethod = _selectedPaymentMethod;
    }

    // Валидация полей в зависимости от способа оплаты (для старой формы)
    if (paymentMethod == 'CASH') {
      if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
        // Проверяем, есть ли accountId в динамической форме
        final accountId = formValues['accountId'] as String?;
        if (accountId == null || accountId.isEmpty) {
          setState(() {
            _error = 'Для наличных необходимо выбрать кассу';
            _isLoading = false;
          });
          return;
        }
      }
    } else if (paymentMethod == 'BANK_TRANSFER' || 
               paymentMethod == 'TERMINAL') {
      if (_selectedFromAccountId == null || _selectedFromAccountId!.isEmpty) {
        // Проверяем, есть ли fromAccountId в динамической форме
        final fromAccountId = formValues['fromAccountId'] as String?;
        if (fromAccountId == null || fromAccountId.isEmpty) {
          setState(() {
            _error = 'Для безналичных необходимо выбрать банковский счет';
            _isLoading = false;
          });
          return;
        }
      }
    }

    if (paymentMethod == null || paymentMethod.isEmpty) {
      setState(() {
        _error = 'Необходимо выбрать способ оплаты';
        _isLoading = false;
      });
      return;
    }

    // Извлекаем accountId и fromAccountId из формы
    // Для динамической формы они могут быть в formValues, для старой формы - в _selectedAccountId/_selectedFromAccountId
    final accountId = formValues['accountId'] as String? ?? _selectedAccountId;
    final fromAccountId = formValues['fromAccountId'] as String? ?? _selectedFromAccountId;

    final fillPaymentDetailsUseCase = Provider.of<FillPaymentDetails>(
      context,
      listen: false,
    );

    // Структура запроса: { paymentMethod, accountId?, fromAccountId? }
    final result = await fillPaymentDetailsUseCase.call(
      FillPaymentDetailsParams(
        approvalId: widget.approvalId,
        paymentMethod: paymentMethod,
        accountId: paymentMethod == 'CASH' ? accountId : null,
        fromAccountId: (paymentMethod == 'BANK_TRANSFER' || 
                       paymentMethod == 'TERMINAL') 
            ? fromAccountId 
            : null,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _error = _getErrorMessage(failure);
          _isLoading = false;
        });
      },
      (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Платежные реквизиты успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
        // Вызываем callback для обновления списка
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.statusWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.payment,
                        color: theme.statusWarning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Заполнить платежные реквизиты',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.approval?.title != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.approval!.title,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Если загружается схема, показываем индикатор
                if (_isLoadingSchema)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                // Если схема загружена, используем динамическую форму
                else if (_formSchema != null) ...[
                  DynamicBlockForm(
                    key: ValueKey('payment-details-${widget.approvalId}'),
                    formSchema: _formSchema,
                    formKey: _formKey,
                    initialValues: _initialValues,
                  ),
                ]
                // Иначе используем старую форму
                else ...[
                  // Способ оплаты
                  FormBuilderDropdown<String>(
                    name: 'paymentMethod',
                    initialValue: _selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Способ оплаты *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'CASH',
                        child: Text('Наличные'),
                      ),
                      DropdownMenuItem(
                        value: 'BANK_TRANSFER',
                        child: Text('Банковский перевод'),
                      ),
                      DropdownMenuItem(
                        value: 'TERMINAL',
                        child: Text('Терминал'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                        // Очищаем выбранные счета при смене способа оплаты
                        _selectedAccountId = null;
                        _selectedFromAccountId = null;
                        // Обновляем значение в форме
                        _formKey.currentState?.fields['accountId']?.didChange(null);
                        _formKey.currentState?.fields['fromAccountId']?.didChange(null);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, выберите способ оплаты';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Поле для кассы (только для CASH)
                  if (_selectedPaymentMethod == 'CASH') ...[
                    if (_isLoadingAccounts)
                      const Center(child: CircularProgressIndicator())
                    else
                      FormBuilderDropdown<String>(
                        name: 'accountId',
                        initialValue: _selectedAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Касса *',
                          border: OutlineInputBorder(),
                        ),
                        items: _cashAccounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.name} (${account.balance.toStringAsFixed(2)} ${account.currency})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedAccountId = value;
                          });
                        },
                        validator: (value) {
                          if (_selectedPaymentMethod == 'CASH' && 
                              (value == null || value.isEmpty)) {
                            return 'Пожалуйста, выберите кассу';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                  // Поле для банковского счета (для BANK_TRANSFER и TERMINAL)
                  if (_selectedPaymentMethod == 'BANK_TRANSFER' || 
                      _selectedPaymentMethod == 'TERMINAL') ...[
                    if (_isLoadingAccounts)
                      const Center(child: CircularProgressIndicator())
                    else
                      FormBuilderDropdown<String>(
                        name: 'fromAccountId',
                        initialValue: _selectedFromAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Банковский счет *',
                          border: OutlineInputBorder(),
                        ),
                        items: _bankAccounts.map((account) {
                          return DropdownMenuItem(
                            value: account.id,
                            child: Text('${account.name} (${account.balance.toStringAsFixed(2)} ${account.currency})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFromAccountId = value;
                          });
                        },
                        validator: (value) {
                          if ((_selectedPaymentMethod == 'BANK_TRANSFER' || 
                               _selectedPaymentMethod == 'TERMINAL') && 
                              (value == null || value.isEmpty)) {
                            return 'Пожалуйста, выберите банковский счет';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Сохранить'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
