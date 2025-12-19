import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/usecases/get_approvals.dart';
import '../../domain/usecases/create_approval.dart';
import '../../domain/usecases/get_approval_templates.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/dynamic_approval_form.dart';
import 'approval_detail_page.dart';

/// Страница согласований
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  List<Approval> _pendingApprovals = [];
  List<Approval> _approvedApprovals = [];
  List<Approval> _rejectedApprovals = [];
  List<Approval> _canApproveApprovals = []; // Согласования, которые пользователь может одобрить
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final currentUser = authProvider.user;

    if (selectedBusiness == null || currentUser == null) {
      setState(() {
        _isLoading = false;
        _error = 'Компания не выбрана или пользователь не авторизован';
      });
      return;
    }

    final getApprovalsUseCase = Provider.of<GetApprovals>(context, listen: false);

    // Загружаем согласования, которые пользователь может одобрить
    final canApproveResult = await getApprovalsUseCase.call(
      GetApprovalsParams(
        businessId: selectedBusiness.id,
        canApprove: true,
      ),
    );

    // Загружаем pending согласования
    final pendingResult = await getApprovalsUseCase.call(
      GetApprovalsParams(
        businessId: selectedBusiness.id,
        status: ApprovalStatus.pending,
      ),
    );

    // Загружаем одобренные согласования
    final approvedResult = await getApprovalsUseCase.call(
      GetApprovalsParams(
        businessId: selectedBusiness.id,
        status: ApprovalStatus.approved,
      ),
    );

    // Загружаем отклоненные согласования
    final rejectedResult = await getApprovalsUseCase.call(
      GetApprovalsParams(
        businessId: selectedBusiness.id,
        status: ApprovalStatus.rejected,
      ),
    );

    setState(() {
      _isLoading = false;
      canApproveResult.fold(
        (failure) => _error = _getErrorMessage(failure),
        (approvals) => _canApproveApprovals = approvals,
      );
      pendingResult.fold(
        (failure) => _error = _getErrorMessage(failure),
        (approvals) => _pendingApprovals = approvals,
      );
      approvedResult.fold(
        (failure) => _error = _getErrorMessage(failure),
        (approvals) => _approvedApprovals = approvals,
      );
      rejectedResult.fold(
        (failure) => _error = _getErrorMessage(failure),
        (approvals) => _rejectedApprovals = approvals,
      );
    });
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  void _showCreateApprovalDialog() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    if (selectedBusiness == null || currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Компания не выбрана или пользователь не авторизован'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateApprovalDialog(
        businessId: selectedBusiness.id,
        currentUserId: currentUser.id,
        onSuccess: () {
          _loadApprovals();
        },
      ),
    );
  }

  String _getStatusText(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return 'Ожидает';
      case ApprovalStatus.approved:
        return 'Одобрено';
      case ApprovalStatus.rejected:
        return 'Отклонено';
      case ApprovalStatus.cancelled:
        return 'Отменено';
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final approvalDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (approvalDate == today) {
      return 'Сегодня ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.add(const Duration(days: 1))) {
      return 'Завтра ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildApprovalCard(Approval approval) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          approval.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (approval.description != null && approval.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  approval.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approval.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(approval.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(approval.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApprovalDetailPage(approvalId: approval.id),
            ),
          ).then((_) => _loadApprovals()); // Обновляем список после возврата
        },
      ),
    );
  }

  Widget _buildApprovalsList(List<Approval> approvals) {
    if (approvals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Нет согласований',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApprovals,
      child: ListView.builder(
        itemCount: approvals.length,
        itemBuilder: (context, index) => _buildApprovalCard(approvals[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Согласования'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApprovals,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Требуют решения', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Ожидают', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Завершенные', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApprovals,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Вкладка "Требуют решения" - показываем согласования, которые пользователь может одобрить
                    _buildApprovalsList(_canApproveApprovals),
                    // Вкладка "Ожидают" - показываем pending согласования
                    _buildApprovalsList(_pendingApprovals),
                    // Вкладка "Завершенные" - показываем одобренные и отклоненные
                    Column(
                      children: [
                        if (_approvedApprovals.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'Одобренные (${_approvedApprovals.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildApprovalsList(_approvedApprovals),
                          ),
                        ],
                        if (_rejectedApprovals.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  'Отклоненные (${_rejectedApprovals.length})',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildApprovalsList(_rejectedApprovals),
                          ),
                        ],
                        if (_approvedApprovals.isEmpty && _rejectedApprovals.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Нет завершенных согласований',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateApprovalDialog,
        child: const Icon(Icons.add),
        tooltip: 'Создать согласование',
      ),
    );
  }
}

/// Диалог создания согласования
class _CreateApprovalDialog extends StatefulWidget {
  final String businessId;
  final String currentUserId;
  final VoidCallback onSuccess;

  const _CreateApprovalDialog({
    required this.businessId,
    required this.currentUserId,
    required this.onSuccess,
  });

  @override
  State<_CreateApprovalDialog> createState() => _CreateApprovalDialogState();
}

class _CreateApprovalDialogState extends State<_CreateApprovalDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<ApprovalTemplate> _templates = [];
  ApprovalTemplate? _selectedTemplate;
  bool _isLoadingTemplates = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _error = null;
    });

    final getTemplatesUseCase = Provider.of<GetApprovalTemplates>(context, listen: false);
    final result = await getTemplatesUseCase.call(
      GetApprovalTemplatesParams(businessId: widget.businessId),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingTemplates = false;
          _error = _getErrorMessage(failure);
        });
      },
      (templates) {
        setState(() {
          _isLoadingTemplates = false;
          _templates = templates.where((t) => t.isActive).toList();
        });
      },
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    final formValues = _formKey.currentState!.value;
    
    // Получаем выбранный шаблон из формы
    final selectedTemplate = formValues['template'] as ApprovalTemplate?;
    if (selectedTemplate == null) {
      setState(() {
        _error = 'Выберите шаблон согласования';
      });
      return;
    }

    // Получаем title и description из формы
    final title = (formValues['title'] as String?)?.trim() ?? selectedTemplate.name;
    final description = (formValues['description'] as String?)?.trim();

    // Получаем данные из динамической формы (исключаем системные поля)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Исключаем системные поля формы
      if (key != 'template' && key != 'title' && key != 'description' && value != null) {
        dynamicFormData[key] = value;
      }
    });

    // Извлекаем requestDate из formData, если он там есть
    DateTime? requestDate;
    if (dynamicFormData.containsKey('requestDate')) {
      final requestDateValue = dynamicFormData['requestDate'];
      if (requestDateValue is DateTime) {
        requestDate = requestDateValue;
      } else if (requestDateValue is String) {
        requestDate = DateTime.tryParse(requestDateValue);
      }
    }
    // Если requestDate не найден в formData, используем текущую дату
    requestDate ??= DateTime.now();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final createApprovalUseCase = Provider.of<CreateApproval>(context, listen: false);

    final approval = Approval(
      id: '', // Будет создан на сервере
      businessId: widget.businessId,
      templateCode: selectedTemplate.code, // Используем код шаблона
      title: title,
      description: description?.isEmpty ?? true ? null : description,
      status: ApprovalStatus.pending,
      createdBy: widget.currentUserId,
      requestDate: requestDate,
      formData: dynamicFormData, // Все данные из динамической формы
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createApprovalUseCase.call(
      CreateApprovalParams(approval: approval),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (createdApproval) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Согласование успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSuccess();
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
    return AlertDialog(
      title: const Text('Создать согласование'),
      content: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoadingTemplates)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_templates.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Text(
                    'Нет доступных шаблонов согласований',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else ...[
                FormBuilderDropdown<ApprovalTemplate>(
                  name: 'template',
                  initialValue: _selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Шаблон согласования *',
                    border: OutlineInputBorder(),
                  ),
                  items: _templates.map((template) {
                    return DropdownMenuItem<ApprovalTemplate>(
                      value: template,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            template.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (template.description != null && template.description!.isNotEmpty)
                            Text(
                              template.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      final oldTemplate = _selectedTemplate;
                      _selectedTemplate = value;
                      _error = null; // Очищаем ошибку при выборе
                      
                      // Автоматически заполняем title из шаблона
                      if (value != null && _titleController.text.isEmpty) {
                        _titleController.text = value.name;
                      }
                      
                      // Очищаем значения полей динамической формы при смене шаблона
                      if (oldTemplate != null && oldTemplate != value && _formKey.currentState != null) {
                        final oldSchema = oldTemplate.formSchema;
                        if (oldSchema != null) {
                          final oldProperties = oldSchema['properties'] as Map<String, dynamic>?;
                          if (oldProperties != null) {
                            for (var fieldName in oldProperties.keys) {
                              // Очищаем поля из старого шаблона
                              _formKey.currentState?.fields[fieldName]?.didChange(null);
                            }
                          }
                        }
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Выберите шаблон согласования';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'title',
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название *',
                    border: OutlineInputBorder(),
                    helperText: 'Можно оставить название из шаблона или изменить',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Название обязательно';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FormBuilderTextField(
                  name: 'description',
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                // Динамическая форма на основе formSchema
                if (_selectedTemplate?.formSchema != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  DynamicApprovalForm(
                    key: ValueKey(_selectedTemplate!.code), // Уникальный key для пересоздания виджета при смене шаблона
                    formSchema: _selectedTemplate!.formSchema,
                    formKey: _formKey,
                  ),
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
          onPressed: _isLoading ? null : _submit,
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
