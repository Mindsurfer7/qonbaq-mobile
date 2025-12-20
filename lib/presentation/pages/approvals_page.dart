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
import '../widgets/dynamic_block_form.dart';
import 'approval_detail_page.dart';

/// Страница согласований
class ApprovalsPage extends StatefulWidget {
  const ApprovalsPage({super.key});

  @override
  State<ApprovalsPage> createState() => _ApprovalsPageState();
}

class _ApprovalsPageState extends State<ApprovalsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  List<Approval> _pendingApprovals = []; // Ожидают (status = PENDING)
  List<Approval> _canApproveApprovals =
      []; // Требуют решения (canApprove = true)
  List<Approval> _allCanApproveApprovals =
      []; // Все согласования в бизнесе (showAll=true)
  List<Approval> _completedApprovals = []; // Завершенные (COMPLETED)
  List<Approval> _approvedApprovals = []; // Утвержденные (APPROVED)
  List<Approval> _rejectedApprovals = []; // Отклоненные (REJECTED)
  late TabController _tabController;
  bool _canApproveInCurrentBusiness = false;
  bool _isLoadingAllApprovals = false; // Флаг загрузки расширенного списка

  @override
  void initState() {
    super.initState();
    // Количество вкладок зависит от прав пользователя
    _checkPermissions();
    _tabController = TabController(
      length: _canApproveInCurrentBusiness ? 3 : 2,
      vsync: this,
    );
    // Слушаем изменения вкладки
    _tabController.addListener(_onTabChanged);
    // Загружаем данные для первой вкладки после инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovalsForTab(0);
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      _loadApprovalsForTab(_tabController.index);
    }
  }

  void _checkPermissions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final currentUser = authProvider.user;

    if (currentUser != null && selectedBusiness != null) {
      _canApproveInCurrentBusiness = currentUser.canApproveInBusiness(
        selectedBusiness.id,
      );
    }
  }

  /// Проверка привилегированных прав (isAuthorizedApprover или isGeneralDirector)
  bool _hasPrivilegedPermissions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final selectedBusiness = profileProvider.selectedBusiness;

    if (currentUser == null || selectedBusiness == null) return false;

    final permission = currentUser.getPermissionsForBusiness(selectedBusiness.id);
    if (permission == null) return false;

    return permission.isAuthorizedApprover || permission.isGeneralDirector;
  }

  /// Загрузка всех согласований в бизнесе (showAll=true)
  Future<void> _loadAllApprovals() async {
    if (_isLoadingAllApprovals) return;

    setState(() {
      _isLoadingAllApprovals = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _isLoadingAllApprovals = false;
      });
      return;
    }

    final getApprovalsUseCase = Provider.of<GetApprovals>(
      context,
      listen: false,
    );
    final result = await getApprovalsUseCase.call(
      GetApprovalsParams(
        businessId: selectedBusiness.id,
        canApprove: true,
        showAll: true,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingAllApprovals = false;
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
      (approvals) {
        setState(() {
          _isLoadingAllApprovals = false;
          _allCanApproveApprovals = approvals;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  /// Загрузка согласований для конкретной вкладки
  Future<void> _loadApprovalsForTab(int tabIndex) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
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

    final getApprovalsUseCase = Provider.of<GetApprovals>(
      context,
      listen: false,
    );

    // Определяем, какая вкладка активна
    // Если есть права: 0 = Требуют решения, 1 = Ожидают, 2 = Завершенные
    // Если нет прав: 0 = Ожидают, 1 = Завершенные
    int actualTabIndex;
    if (_canApproveInCurrentBusiness) {
      // Есть права: tabIndex соответствует actualTabIndex
      actualTabIndex = tabIndex;
    } else {
      // Нет прав: tabIndex 0 = Ожидают (actualTabIndex 1), tabIndex 1 = Завершенные (actualTabIndex 2)
      actualTabIndex = tabIndex + 1;
    }

    try {
      if (actualTabIndex == 0) {
        // Вкладка "Требуют решения" - используем canApprove=true
        // Бэкенд должен вернуть согласования со статусами PENDING и IN_EXECUTION
        final result = await getApprovalsUseCase.call(
          GetApprovalsParams(businessId: selectedBusiness.id, canApprove: true),
        );
        result.fold(
          (failure) {
            setState(() {
              _isLoading = false;
              _error = _getErrorMessage(failure);
            });
          },
          (approvals) {
            setState(() {
              _isLoading = false;
              _canApproveApprovals = approvals;
            });
          },
        );
      } else if (actualTabIndex == 1) {
        // Вкладка "Ожидают" - загружаем DRAFT и PENDING
        final draftResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.draft,
          ),
        );
        final pendingResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.pending,
          ),
        );

        List<Approval> allPending = [];
        draftResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (approvals) => allPending.addAll(approvals),
        );
        pendingResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (approvals) => allPending.addAll(approvals),
        );

        setState(() {
          _isLoading = false;
          _pendingApprovals = allPending;
        });
      } else if (actualTabIndex == 2) {
        // Вкладка "Завершенные" - загружаем COMPLETED, APPROVED, REJECTED
        final completedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.completed,
          ),
        );
        final approvedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.approved,
          ),
        );
        final rejectedResult = await getApprovalsUseCase.call(
          GetApprovalsParams(
            businessId: selectedBusiness.id,
            status: ApprovalStatus.rejected,
          ),
        );

        List<Approval> completed = [];
        List<Approval> approved = [];
        List<Approval> rejected = [];

        completedResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (approvals) => completed = approvals,
        );
        approvedResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (approvals) => approved = approvals,
        );
        rejectedResult.fold(
          (failure) => _error = _getErrorMessage(failure),
          (approvals) => rejected = approvals,
        );

        setState(() {
          _isLoading = false;
          _completedApprovals = completed;
          _approvedApprovals = approved;
          _rejectedApprovals = rejected;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка при загрузке: $e';
      });
    }
  }

  /// Старый метод для обратной совместимости (используется при обновлении после создания)
  Future<void> _loadApprovals() async {
    // Загружаем данные для текущей активной вкладки
    _loadApprovalsForTab(_tabController.index);
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
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
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
      barrierDismissible: false, // Предотвращаем закрытие при клике вне диалога
      builder:
          (dialogContext) => _CreateApprovalDialog(
            businessId: selectedBusiness.id,
            currentUserId: currentUser.id,
            onSuccess: () {
              // Обновляем список согласований после успешного создания
              _loadApprovals();
            },
            onApprovalCreated: (approval) {
              // Оптимистично добавляем созданное согласование в список
              // Если статус DRAFT или PENDING, добавляем во вкладку "Ожидают"
              if (approval.status == ApprovalStatus.draft ||
                  approval.status == ApprovalStatus.pending) {
                setState(() {
                  // Добавляем в начало списка pending
                  _pendingApprovals.insert(0, approval);
                });
              }
            },
          ),
    );
  }

  String _getStatusText(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return 'Черновик';
      case ApprovalStatus.pending:
        return 'На согласовании';
      case ApprovalStatus.approved:
        return 'Утверждено';
      case ApprovalStatus.rejected:
        return 'Отклонено';
      case ApprovalStatus.inExecution:
        return 'В исполнении';
      case ApprovalStatus.completed:
        return 'Завершено';
      case ApprovalStatus.cancelled:
        return 'Отменено';
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return Colors.grey;
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.inExecution:
        return Colors.blue;
      case ApprovalStatus.completed:
        return Colors.teal;
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
            if (approval.description != null &&
                approval.description!.isNotEmpty)
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        padding: const EdgeInsets.only(top: 20),
        itemCount: approvals.length,
        itemBuilder: (context, index) => _buildApprovalCard(approvals[index]),
      ),
    );
  }

  /// Виджет для вкладки "Требуют решения" с аккордеоном для привилегированных
  Widget _buildCanApproveTab() {
    final hasPrivileges = _hasPrivilegedPermissions();

    if (!hasPrivileges) {
      // Обычный пользователь - просто список
      return _buildApprovalsList(_canApproveApprovals);
    }

    // Привилегированный пользователь - аккордеон
    return RefreshIndicator(
      onRefresh: () => _loadApprovalsForTab(0),
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          // Основной список (свои согласования)
          if (_canApproveApprovals.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Мои согласования (${_canApproveApprovals.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ..._canApproveApprovals.map((approval) => _buildApprovalCard(approval)),
          ] else
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Нет согласований',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),

          // Аккордеон для всех согласований
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: ExpansionTile(
              title: const Text(
                'Все согласования в бизнесе',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: _isLoadingAllApprovals
                  ? const Text('Загрузка...')
                  : Text('${_allCanApproveApprovals.length} согласований'),
              leading: const Icon(Icons.business),
              initiallyExpanded: false,
              onExpansionChanged: (expanded) {
                if (expanded &&
                    _allCanApproveApprovals.isEmpty &&
                    !_isLoadingAllApprovals) {
                  // Загружаем только при первом раскрытии
                  _loadAllApprovals();
                }
              },
              children: [
                if (_isLoadingAllApprovals)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allCanApproveApprovals.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Нет согласований',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._allCanApproveApprovals
                      .map((approval) => _buildApprovalCard(approval)),
              ],
            ),
          ),
        ],
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
          tabs: [
            if (_canApproveInCurrentBusiness)
              const Tab(
                text: 'Требуют решения',
                icon: Icon(Icons.pending_actions),
              ),
            const Tab(text: 'Ожидают', icon: Icon(Icons.hourglass_empty)),
            const Tab(text: 'Завершенные', icon: Icon(Icons.check_circle)),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
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
                  if (_canApproveInCurrentBusiness)
                    _buildCanApproveTab(),
                  _buildApprovalsList(_pendingApprovals),
                  _buildCompletedTab(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateApprovalDialog,
        child: const Icon(Icons.add),
        tooltip: 'Создать согласование',
      ),
    );
  }

  /// Вкладка "Завершенные" с разделением по статусам
  Widget _buildCompletedTab() {
    final hasAny =
        _completedApprovals.isNotEmpty ||
        _approvedApprovals.isNotEmpty ||
        _rejectedApprovals.isNotEmpty;

    if (!hasAny) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Нет завершенных согласований',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApprovals,
      child: ListView(
        children: [
          if (_completedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Завершено', _completedApprovals.length),
            ..._completedApprovals.map(_buildApprovalCard),
          ],
          if (_approvedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Утверждено', _approvedApprovals.length),
            ..._approvedApprovals.map(_buildApprovalCard),
          ],
          if (_rejectedApprovals.isNotEmpty) ...[
            _buildSectionHeader('Отклонено', _rejectedApprovals.length),
            ..._rejectedApprovals.map(_buildApprovalCard),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

/// Диалог создания согласования
class _CreateApprovalDialog extends StatefulWidget {
  final String businessId;
  final String currentUserId;
  final VoidCallback onSuccess;
  final Function(Approval)?
  onApprovalCreated; // Callback для оптимистичного обновления

  const _CreateApprovalDialog({
    required this.businessId,
    required this.currentUserId,
    required this.onSuccess,
    this.onApprovalCreated,
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

    final getTemplatesUseCase = Provider.of<GetApprovalTemplates>(
      context,
      listen: false,
    );
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
    if (_formKey.currentState == null) {
      setState(() {
        _error = 'Ошибка формы';
      });
      return;
    }

    // Сохраняем значения формы перед валидацией
    _formKey.currentState!.save();

    // Валидируем форму
    if (!_formKey.currentState!.validate()) {
      // Если валидация не прошла, находим первое поле с ошибкой
      final fields = _formKey.currentState!.fields;
      String? firstError;
      for (var entry in fields.entries) {
        final field = entry.value;
        if (field.hasError) {
          firstError = field.errorText;
          break;
        }
      }
      setState(() {
        _error = firstError ?? 'Пожалуйста, заполните все обязательные поля';
      });
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
    // title теперь опциональное - если не указано, бэкенд использует название шаблона
    final title = (formValues['title'] as String?)?.trim();
    final description = (formValues['description'] as String?)?.trim();

    // Получаем данные из динамической формы (исключаем системные поля)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Исключаем системные поля формы
      if (key != 'template' &&
          key != 'title' &&
          key != 'description' &&
          value != null) {
        // Удаляем processName из formData - бэкенд его автоматически удаляет
        if (key == 'processName') {
          return; // Пропускаем processName
        }

        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[key] = value.toIso8601String();
        } else if (value is ApprovalTemplate) {
          // Пропускаем объекты шаблонов
        } else {
          dynamicFormData[key] = value;
        }
      }
    });

    // Проверяем, что есть данные формы
    if (dynamicFormData.isEmpty && selectedTemplate.formSchema != null) {
      final schema = selectedTemplate.formSchema!;
      final properties = schema['properties'] as Map<String, dynamic>?;
      if (properties != null && properties.isNotEmpty) {
        // Если есть поля в схеме, но они не заполнены, это может быть проблемой
        // Но не блокируем отправку, так как некоторые поля могут быть опциональными
      }
    }

    // Извлекаем requestDate из formData, ТОЛЬКО если поле есть в форме
    // requestDate теперь опциональное - если не указано, бэкенд установит текущую дату
    DateTime? requestDate;
    if (dynamicFormData.containsKey('requestDate')) {
      final requestDateValue = dynamicFormData['requestDate'];
      if (requestDateValue is DateTime) {
        requestDate = requestDateValue;
        // Удаляем из formData, так как requestDate отправляется отдельно
        dynamicFormData.remove('requestDate');
      } else if (requestDateValue is String) {
        // Если это уже строка (ISO формат), парсим её
        requestDate = DateTime.tryParse(requestDateValue);
        if (requestDate != null) {
          // Удаляем из formData, так как requestDate отправляется отдельно
          dynamicFormData.remove('requestDate');
        } else {
          // Если не удалось распарсить, удаляем из formData, но не отправляем requestDate
          dynamicFormData.remove('requestDate');
        }
      }
    }
    // Если requestDate не найден в formData, НЕ устанавливаем его
    // Бэкенд сам установит текущую дату, если нужно

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final createApprovalUseCase = Provider.of<CreateApproval>(
      context,
      listen: false,
    );

    final approval = Approval(
      id: '', // Будет создан на сервере
      businessId: widget.businessId,
      templateCode: selectedTemplate.code, // Используем код шаблона
      title:
          title ??
          selectedTemplate
              .name, // Если title не указан, используем название шаблона (бэкенд тоже так сделает)
      description: description?.isEmpty ?? true ? null : description,
      status: ApprovalStatus.pending,
      createdBy: widget.currentUserId,
      requestDate:
          requestDate, // Опциональное - бэкенд установит текущую дату, если не указано
      formData:
          dynamicFormData, // Все данные из динамической формы (без processName)
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

        // Если это ошибка валидации, применяем ошибки к полям формы
        if (failure is ValidationFailure && _formKey.currentState != null) {
          for (var error in failure.errors) {
            final fieldName = error.field;
            final field = _formKey.currentState?.fields[fieldName];
            if (field != null) {
              field.invalidate(error.message);
              field.validate();
            }
          }
        }
      },
      (createdApproval) {
        // Оптимистично добавляем созданное согласование в список
        if (widget.onApprovalCreated != null) {
          widget.onApprovalCreated!(createdApproval);
        }

        // Закрываем диалог СРАЗУ после успешного создания
        Navigator.of(context).pop(true);

        // Вызываем onSuccess для обновления списка (перезагрузка с сервера)
        widget.onSuccess();

        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Согласование успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
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
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
                    items:
                        _templates.map((template) {
                          return DropdownMenuItem<ApprovalTemplate>(
                            value: template,
                            child: Text(
                              template.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
                        if (oldTemplate != null &&
                            oldTemplate != value &&
                            _formKey.currentState != null) {
                          final oldSchema = oldTemplate.formSchema;
                          if (oldSchema != null) {
                            final oldProperties =
                                oldSchema['properties']
                                    as Map<String, dynamic>?;
                            if (oldProperties != null) {
                              for (var fieldName in oldProperties.keys) {
                                // Очищаем поля из старого шаблона
                                _formKey.currentState?.fields[fieldName]
                                    ?.didChange(null);
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
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                      helperText:
                          'Оставьте пустым, чтобы использовать название из шаблона',
                    ),
                    // title теперь опциональное - валидация не требуется
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
                    DynamicBlockForm(
                      key: ValueKey(
                        _selectedTemplate!.code,
                      ), // Уникальный key для пересоздания виджета при смене шаблона
                      formSchema: _selectedTemplate!.formSchema,
                      formKey: _formKey,
                    ),
                  ],
                  // Добавляем отступ снизу для корректного скролла
                  const SizedBox(height: 8),
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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
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
