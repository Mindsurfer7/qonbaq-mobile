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

/// Страница заявок на оплату
class PaymentRequestsPage extends StatelessWidget {
  const PaymentRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на оплату'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          _buildCreateButton(
            context,
            'Заявка на безналичную оплату',
            'Создать заявку на безналичную оплату',
            Icons.account_balance,
            Colors.blue,
            FinancialFormType.cashless,
          ),
          const SizedBox(height: 16),
          _buildCreateButton(
            context,
            'Заявка на наличную оплату',
            'Создать заявку на наличную оплату',
            Icons.money,
            Colors.green,
            FinancialFormType.cash,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    FinancialFormType formType,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showCreateFinancialRequestDialog(context, formType),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

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

    // Получаем данные из динамической формы (исключаем системные поля)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Исключаем системные поля формы
      if (key != 'title' && key != 'description' && value != null) {
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
