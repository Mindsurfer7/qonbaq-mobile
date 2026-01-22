import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/account.dart';
import '../../domain/usecases/fill_payment_details.dart';
import '../../domain/usecases/get_accounts.dart';
import '../../core/error/failures.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/profile_provider.dart';

/// Диалог для заполнения платежных реквизитов
class PaymentDetailsDialog extends StatefulWidget {
  final Approval approval;
  final VoidCallback? onSuccess;

  const PaymentDetailsDialog({
    super.key,
    required this.approval,
    this.onSuccess,
  });

  @override
  State<PaymentDetailsDialog> createState() => _PaymentDetailsDialogState();
}

class _PaymentDetailsDialogState extends State<PaymentDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingAccounts = false;
  String? _error;
  
  String? _selectedPaymentMethod; // "CASH" | "BANK_TRANSFER" | "TERMINAL"
  String? _selectedAccountId; // Для CASH
  String? _selectedFromAccountId; // Для BANK_TRANSFER/TERMINAL
  
  List<Account> _cashAccounts = []; // Кассы для CASH
  List<Account> _bankAccounts = []; // Банковские счета для BANK_TRANSFER/TERMINAL

  @override
  void initState() {
    super.initState();
    // Предзаполняем поля из formData, если они уже есть
    if (widget.approval.formData != null) {
      _selectedPaymentMethod = widget.approval.formData!['paymentMethod']?.toString();
      _selectedAccountId = widget.approval.formData!['accountId']?.toString();
      _selectedFromAccountId = widget.approval.formData!['fromAccountId']?.toString();
    }
    _loadAccounts();
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Валидация полей в зависимости от способа оплаты
    if (_selectedPaymentMethod == 'CASH') {
      if (_selectedAccountId == null || _selectedAccountId!.isEmpty) {
        setState(() {
          _error = 'Для наличных необходимо выбрать кассу';
          _isLoading = false;
        });
        return;
      }
    } else if (_selectedPaymentMethod == 'BANK_TRANSFER' || 
               _selectedPaymentMethod == 'TERMINAL') {
      if (_selectedFromAccountId == null || _selectedFromAccountId!.isEmpty) {
        setState(() {
          _error = 'Для безналичных необходимо выбрать банковский счет';
          _isLoading = false;
        });
        return;
      }
    }

    final fillPaymentDetailsUseCase = Provider.of<FillPaymentDetails>(
      context,
      listen: false,
    );

    final result = await fillPaymentDetailsUseCase.call(
      FillPaymentDetailsParams(
        approvalId: widget.approval.id,
        paymentMethod: _selectedPaymentMethod!,
        accountId: _selectedPaymentMethod == 'CASH' ? _selectedAccountId : null,
        fromAccountId: (_selectedPaymentMethod == 'BANK_TRANSFER' || 
                       _selectedPaymentMethod == 'TERMINAL') 
            ? _selectedFromAccountId 
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
          child: Form(
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
                          const SizedBox(height: 4),
                          Text(
                            widget.approval.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Способ оплаты
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
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
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
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
                    DropdownButtonFormField<String>(
                      value: _selectedFromAccountId,
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
