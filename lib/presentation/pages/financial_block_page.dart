import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/usecases/get_financial_form.dart';
import '../../domain/usecases/create_approval.dart';
import '../../core/error/failures.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/dynamic_block_form.dart';

/// Страница финансового блока
class FinancialBlockPage extends StatelessWidget {
  const FinancialBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый блок'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // Левый верхний: Заявки на оплату
          _buildPaymentRequestsBlock(context),
          // Правый верхний: Расход/Приход
          _buildIncomeExpenseBlock(context),
          // Левый нижний: Начисления ЗП
          _buildSalaryBlock(context),
          // Правый нижний: Аналитический блок
          _buildAnalyticsBlock(context),
        ],
      ),
    );
  }

  /// Левый верхний блок: Заявки на оплату
  Widget _buildPaymentRequestsBlock(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заявки на оплату',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSmallPaymentButton(
                    context,
                    'Безналичная',
                    Icons.account_balance,
                    Colors.blue,
                    FinancialFormType.cashless,
                  ),
                  const SizedBox(height: 8),
                  _buildSmallPaymentButton(
                    context,
                    'Наличная',
                    Icons.money,
                    Colors.green,
                    FinancialFormType.cash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Маленькая кнопка для заявки на оплату
  Widget _buildSmallPaymentButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    FinancialFormType formType,
  ) {
    return InkWell(
      onTap: () => _showCreateFinancialRequestDialog(context, formType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Правый верхний блок: Расход/Приход
  Widget _buildIncomeExpenseBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расход / Приход',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIncomeExpenseItem(
                    Icons.trending_up,
                    'Приход',
                    '0 ₽',
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildIncomeExpenseItem(
                    Icons.trending_down,
                    'Расход',
                    '0 ₽',
                    Colors.red,
                  ),
                  const SizedBox(height: 12),
                  _buildIncomeExpenseItem(
                    Icons.swap_horiz,
                    'Транзит',
                    '0 ₽',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Элемент прихода/расхода
  Widget _buildIncomeExpenseItem(
    IconData icon,
    String label,
    String amount,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Левый нижний блок: Начисления ЗП
  Widget _buildSalaryBlock(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet,
              size: 32,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            const Text(
              'Начисления ЗП',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Оклад',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '0 ₽',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Правый нижний блок: Аналитический блок
  Widget _buildAnalyticsBlock(BuildContext context) {
    return Card(
      color: Colors.amber.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 32,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 8),
            const Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Показать диалог создания финансовой заявки
  void _showCreateFinancialRequestDialog(
    BuildContext context,
    FinancialFormType type,
  ) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не выбран бизнес'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateFinancialRequestDialog(
        formType: type,
        businessId: selectedBusiness.id,
      ),
    );
  }
}

/// Диалог создания финансовой заявки
class _CreateFinancialRequestDialog extends StatefulWidget {
  final FinancialFormType formType;
  final String businessId;

  const _CreateFinancialRequestDialog({
    required this.formType,
    required this.businessId,
  });

  @override
  State<_CreateFinancialRequestDialog> createState() =>
      _CreateFinancialRequestDialogState();
}

class _CreateFinancialRequestDialogState
    extends State<_CreateFinancialRequestDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  ApprovalTemplate? _template;
  bool _isLoadingForm = true;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoadingForm = true;
      _error = null;
    });

    final getFinancialFormUseCase = Provider.of<GetFinancialForm>(
      context,
      listen: false,
    );

    final result = await getFinancialFormUseCase.call(
      GetFinancialFormParams(
        type: widget.formType,
        businessId: widget.businessId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingForm = false;
          _error = _getErrorMessage(failure);
        });
      },
      (template) {
        setState(() {
          _isLoadingForm = false;
          _template = template;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  Future<void> _submit() async {
    if (_template == null || _formKey.currentState == null) return;

    _formKey.currentState!.save();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final formValues = _formKey.currentState!.value;

    // Извлекаем paymentDueDate из formData (обязательное поле)
    // Поддерживаем оба варианта: paymentDueDate и requestDate (на случай, если маппинг не сработал)
    DateTime? paymentDueDate;
    if (formValues.containsKey('paymentDueDate')) {
      final paymentDueDateValue = formValues['paymentDueDate'];
      if (paymentDueDateValue is DateTime) {
        paymentDueDate = paymentDueDateValue;
      } else if (paymentDueDateValue is String) {
        paymentDueDate = DateTime.tryParse(paymentDueDateValue);
      }
    } else if (formValues.containsKey('requestDate')) {
      // Fallback на старое название (на случай, если маппинг не сработал)
      final requestDateValue = formValues['requestDate'];
      if (requestDateValue is DateTime) {
        paymentDueDate = requestDateValue;
      } else if (requestDateValue is String) {
        paymentDueDate = DateTime.tryParse(requestDateValue);
      }
    }

    // Проверяем наличие обязательного поля paymentDueDate
    if (paymentDueDate == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Поле "Дата оплаты" обязательно для заполнения';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Поле "Дата оплаты" обязательно для заполнения'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Получаем данные из динамической формы (исключаем системные поля и paymentDueDate/requestDate)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Исключаем системные поля формы и paymentDueDate/requestDate (отправляется отдельно)
      if (key != 'title' && key != 'description' && key != 'paymentDueDate' && key != 'requestDate' && value != null) {
        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[key] = value.toIso8601String();
        } else {
          dynamicFormData[key] = value;
        }
      }
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) {
      setState(() {
        _isSubmitting = false;
        _error = 'Пользователь не авторизован';
      });
      return;
    }

    final createApprovalUseCase = Provider.of<CreateApproval>(
      context,
      listen: false,
    );

    final approval = Approval(
      id: '',
      businessId: widget.businessId,
      templateCode: _template!.code,
      title: _template!.name,
      status: ApprovalStatus.pending,
      createdBy: currentUserId,
      paymentDueDate: paymentDueDate,
      formData: dynamicFormData.isNotEmpty ? dynamicFormData : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createApprovalUseCase.call(
      CreateApprovalParams(approval: approval),
    );

    result.fold(
      (failure) {
        setState(() {
          _isSubmitting = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (createdApproval) {
        setState(() {
          _isSubmitting = false;
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Финансовая заявка успешно создана'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.formType == FinancialFormType.cashless
            ? 'Заявка на безналичную оплату'
            : 'Заявка на наличную оплату',
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: _isLoadingForm
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadForm,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : _template == null
                      ? const Text('Шаблон не найден')
                      : FormBuilder(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_template!.formSchema != null)
                                DynamicBlockForm(
                                  formSchema: _template!.formSchema,
                                  formKey: _formKey,
                                ),
                            ],
                          ),
                        ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: (_isSubmitting || _isLoadingForm || _template == null)
              ? null
              : _submit,
          child: _isSubmitting
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









