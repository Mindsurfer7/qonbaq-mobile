import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/usecases/get_fixed_assets.dart';
import '../../domain/usecases/create_fixed_asset.dart';
import '../../domain/usecases/create_approval.dart';
import '../../domain/usecases/get_approval_template_by_code.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';
import '../providers/department_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_confirmations_provider.dart';
import '../widgets/create_fixed_asset_form.dart';
import '../widgets/fixed_asset_card.dart';
import '../widgets/dynamic_block_form.dart';
import '../widgets/pending_confirmations_section.dart';
import '../../core/theme/theme_extensions.dart';

/// Страница основных средств
class FixedAssetsPage extends StatefulWidget {
  const FixedAssetsPage({super.key});

  @override
  State<FixedAssetsPage> createState() => _FixedAssetsPageState();
}

const int _pageLimit = 20;
const String _fixedAssetTransferTemplateCode = 'FIXED_ASSET_TRANSFER';

class _FixedAssetsPageState extends State<FixedAssetsPage> {
  List<FixedAsset> _assets = [];
  bool _isLoading = false;
  String? _error;
  PaginationMeta? _meta;
  int _page = 1;

  // Фильтры
  String? _filterProjectId;
  String? _filterDepartmentId;
  String? _filterCurrentOwnerId;
  AssetCondition? _filterCondition;
  AssetType? _filterType;
  bool _includeArchived = false;

  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFilterData();
      _loadAssets();
    });
  }

  void _loadFilterData() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) return;
    final businessId = selectedBusiness.id;
    Provider.of<ProjectProvider>(
      context,
      listen: false,
    ).loadProjects(businessId);
    Provider.of<DepartmentProvider>(
      context,
      listen: false,
    ).loadDepartments(businessId);
    _loadEmployees(businessId);
    Provider.of<PendingConfirmationsProvider>(
      context,
      listen: false,
    ).loadPendingConfirmations(businessId: businessId);
  }

  Future<void> _refreshAll() async {
    await _loadAssets();
    if (!mounted) return;
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) return;
    await Provider.of<PendingConfirmationsProvider>(
      context,
      listen: false,
    ).loadPendingConfirmations(businessId: selectedBusiness.id);
  }

  Widget _buildFixedAssetsPendingConfirmationsSection() {
    return PendingConfirmationsSection(
      headerText: 'Требует подтверждения (ОС)',
      headerPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      showDivider: true,
      filter: (pc) {
        final code = pc.approval.template?.code ?? pc.approval.templateCode;
        if (code == null || code.trim().isEmpty) return false;
        final normalized = code.toUpperCase().replaceAll('-', '_');
        return normalized == _fixedAssetTransferTemplateCode;
      },
      onConfirmed: _refreshAll,
    );
  }

  Future<void> _loadEmployees(String businessId) async {
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final result = await userRepository.getBusinessEmployees(businessId);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _employees = []),
      (list) => setState(() => _employees = list),
    );
  }

  void _applyFilters() {
    setState(() => _page = 1);
    _loadAssets();
  }

  void _resetFilters() {
    setState(() {
      _filterProjectId = null;
      _filterDepartmentId = null;
      _filterCurrentOwnerId = null;
      _filterCondition = null;
      _filterType = null;
      _includeArchived = false;
      _page = 1;
    });
    _loadAssets();
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() => _error = 'Компания не выбрана');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getFixedAssetsUseCase = Provider.of<GetFixedAssets>(
      context,
      listen: false,
    );
    final result = await getFixedAssetsUseCase.call(
      GetFixedAssetsParams(
        businessId: selectedBusiness.id,
        projectId: _filterProjectId,
        departmentId: _filterDepartmentId,
        currentOwnerId: _filterCurrentOwnerId,
        condition: _filterCondition,
        type: _filterType,
        includeArchived: _includeArchived,
        page: _page,
        limit: _pageLimit,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _error =
              failure.message.isNotEmpty
                  ? failure.message
                  : 'Ошибка при загрузке основных средств';
          _isLoading = false;
        });
      },
      (paginated) {
        setState(() {
          _assets = paginated.items;
          _meta = paginated.meta;
          _isLoading = false;
        });
      },
    );
  }

  String _getAssetTypeName(AssetType type) {
    switch (type) {
      case AssetType.equipment:
        return 'Оборудование';
      case AssetType.furniture:
        return 'Мебель';
      case AssetType.officeTech:
        return 'Орг.техника';
      case AssetType.other:
        return 'Прочее';
    }
  }

  String _getAssetConditionName(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return 'Новое (до 3-х месяцев)';
      case AssetCondition.good:
        return 'Хорошее';
      case AssetCondition.satisfactory:
        return 'Удовлетворительное';
      case AssetCondition.notWorking:
        return 'Не рабочее';
      case AssetCondition.writtenOff:
        return 'Списано по акту';
    }
  }

  bool get _shouldShowPagination =>
      _meta != null && (_meta!.totalPages ?? 1) > 1;

  void _showCreateAssetDialog() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final createFixedAssetUseCase = Provider.of<CreateFixedAsset>(
      context,
      listen: false,
    );
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) return;

    showDialog(
      context: context,
      builder:
          (context) => _CreateFixedAssetDialog(
            businessId: selectedBusiness.id,
            userRepository: userRepository,
            createFixedAssetUseCase: createFixedAssetUseCase,
            onSuccess: () {
              _loadAssets();
            },
          ),
    );
  }

  void _showTransferDialog() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final createApprovalUseCase = Provider.of<CreateApproval>(
      context,
      listen: false,
    );
    final getApprovalTemplateByCode = Provider.of<GetApprovalTemplateByCode>(
      context,
      listen: false,
    );

    if (selectedBusiness == null) return;
    final currentUserId = authProvider.user?.id;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder:
          (context) => _TransferFixedAssetDialog(
            businessId: selectedBusiness.id,
            currentUserId: currentUserId,
            createApprovalUseCase: createApprovalUseCase,
            getApprovalTemplateByCode: getApprovalTemplateByCode,
            onSuccess: () {
              _loadAssets();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Основные средства'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Выберите компанию')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Основные средства'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAssets),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            title: const Text('Фильтры'),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFilterContent(),
              ),
            ],
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "transfer_fixed_asset",
            onPressed: _showTransferDialog,
            backgroundColor: context.appTheme.accentPrimary,
            foregroundColor: Colors.black,
            mini: true,
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "create_fixed_asset",
            onPressed: _showCreateAssetDialog,
            backgroundColor: context.appTheme.accentPrimary,
            foregroundColor: Colors.black,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildFixedAssetsPendingConfirmationsSection(),
                if (_assets.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Нет основных средств',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._assets.map(
                    (asset) => FixedAssetCard(
                      asset: asset,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/business/admin/fixed_assets/detail',
                          arguments: asset.id,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_shouldShowPagination) _buildPaginationBar(),
      ],
    );
  }

  Widget _buildFilterContent() {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Проект
        DropdownButtonFormField<String?>(
          value: _filterProjectId,
          decoration: const InputDecoration(
            labelText: 'Проект',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все')),
            ...(projectProvider.projects ?? []).map(
              (p) => DropdownMenuItem(value: p.id, child: Text(p.name)),
            ),
          ],
          onChanged: (v) => setState(() => _filterProjectId = v),
        ),
        const SizedBox(height: 12),
        // Департамент
        DropdownButtonFormField<String?>(
          value: _filterDepartmentId,
          decoration: const InputDecoration(
            labelText: 'Департамент',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все')),
            ...(departmentProvider.departments ?? []).map(
              (d) => DropdownMenuItem(value: d.id, child: Text(d.name)),
            ),
          ],
          onChanged: (v) => setState(() => _filterDepartmentId = v),
        ),
        const SizedBox(height: 12),
        // Владелец
        DropdownButtonFormField<String?>(
          value: _filterCurrentOwnerId,
          decoration: const InputDecoration(
            labelText: 'Владелец',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все')),
            ..._employees.map(
              (e) => DropdownMenuItem(value: e.id, child: Text(e.fullName)),
            ),
          ],
          onChanged: (v) => setState(() => _filterCurrentOwnerId = v),
        ),
        const SizedBox(height: 12),
        // Состояние
        DropdownButtonFormField<AssetCondition?>(
          value: _filterCondition,
          decoration: const InputDecoration(
            labelText: 'Состояние',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все')),
            ...AssetCondition.values.map(
              (c) => DropdownMenuItem(
                value: c,
                child: Text(_getAssetConditionName(c)),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _filterCondition = v),
        ),
        const SizedBox(height: 12),
        // Тип
        DropdownButtonFormField<AssetType?>(
          value: _filterType,
          decoration: const InputDecoration(
            labelText: 'Тип',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Все')),
            ...AssetType.values.map(
              (t) =>
                  DropdownMenuItem(value: t, child: Text(_getAssetTypeName(t))),
            ),
          ],
          onChanged: (v) => setState(() => _filterType = v),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Включать архивные'),
          value: _includeArchived,
          onChanged: (v) => setState(() => _includeArchived = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: _resetFilters, child: const Text('Сбросить')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Применить'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaginationBar() {
    final page = _meta?.page ?? 1;
    final totalPages = _meta?.totalPages ?? 1;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => _goToPage(page - 1) : null,
          ),
          Text('Стр. $page из $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: page < totalPages ? () => _goToPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}

/// Диалог создания основного средства
class _CreateFixedAssetDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateFixedAsset createFixedAssetUseCase;
  final VoidCallback onSuccess;

  const _CreateFixedAssetDialog({
    required this.businessId,
    required this.userRepository,
    required this.createFixedAssetUseCase,
    required this.onSuccess,
  });

  @override
  State<_CreateFixedAssetDialog> createState() =>
      _CreateFixedAssetDialogState();
}

class _CreateFixedAssetDialogState extends State<_CreateFixedAssetDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Создать основное средство',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Форма
            Expanded(
              child: CreateFixedAssetForm(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                error: _error,
                validationErrors: _validationErrors,
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                },
                onSubmit: (asset) async {
                  final result = await widget.createFixedAssetUseCase.call(
                    CreateFixedAssetParams(asset: asset),
                  );

                  result.fold(
                    (failure) {
                      // Обрабатываем ошибки валидации
                      if (failure is ValidationFailure) {
                        setState(() {
                          _error = failure.serverMessage ?? failure.message;
                          _validationErrors = failure.errors;
                        });
                      } else {
                        setState(() {
                          _error = _getErrorMessage(failure);
                          _validationErrors = null;
                        });
                      }
                    },
                    (createdAsset) {
                      // Закрываем диалог и показываем успех
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Основное средство успешно создано'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        widget.onSuccess();
                      }
                    },
                  );
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог создания согласования перемещения основного средства
class _TransferFixedAssetDialog extends StatefulWidget {
  final String businessId;
  final String currentUserId;
  final CreateApproval createApprovalUseCase;
  final GetApprovalTemplateByCode getApprovalTemplateByCode;
  final VoidCallback onSuccess;

  const _TransferFixedAssetDialog({
    required this.businessId,
    required this.currentUserId,
    required this.createApprovalUseCase,
    required this.getApprovalTemplateByCode,
    required this.onSuccess,
  });

  @override
  State<_TransferFixedAssetDialog> createState() =>
      _TransferFixedAssetDialogState();
}

class _TransferFixedAssetDialogState extends State<_TransferFixedAssetDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ApprovalTemplate? _template;
  bool _isLoadingTemplate = true;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplate() async {
    setState(() {
      _isLoadingTemplate = true;
      _error = null;
    });

    final result = await widget.getApprovalTemplateByCode.call(
      GetApprovalTemplateByCodeParams(
        code: _fixedAssetTransferTemplateCode,
        businessId: widget.businessId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingTemplate = false;
          _error = _getErrorMessage(failure);
        });
      },
      (template) {
        setState(() {
          _isLoadingTemplate = false;
          _template = template;
          // Автоматически заполняем title из шаблона
          _titleController.text = template.name;
        });
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

  Future<void> _submit() async {
    if (_formKey.currentState == null) {
      setState(() {
        _error = 'Ошибка формы';
      });
      return;
    }

    if (_template == null) {
      setState(() {
        _error = 'Шаблон не загружен';
      });
      return;
    }

    // Сохраняем значения формы перед валидацией
    _formKey.currentState!.save();

    // Валидируем форму
    if (!_formKey.currentState!.validate()) {
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

    // Получаем title и description из формы
    final title =
        (_titleController.text.trim().isEmpty)
            ? null
            : _titleController.text.trim();
    final description =
        (_descriptionController.text.trim().isEmpty)
            ? null
            : _descriptionController.text.trim();

    // Получаем данные из динамической формы (исключаем системные поля)
    final dynamicFormData = <String, dynamic>{};
    formValues.forEach((key, value) {
      // Получаем имя поля без префикса блока
      final fieldName = key.contains('.') ? key.split('.').last : key;
      // Исключаем системные поля формы
      if (fieldName != 'title' &&
          fieldName != 'description' &&
          fieldName != 'paymentDueDate' &&
          fieldName != 'requestDate' &&
          fieldName != 'processName' &&
          value != null) {
        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[fieldName] = value.toIso8601String();
        } else if (value is ApprovalTemplate) {
          // Пропускаем объекты шаблонов
        } else {
          dynamicFormData[fieldName] = value;
        }
      }
    });

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final approval = Approval(
      id: '',
      businessId: widget.businessId,
      templateCode: _fixedAssetTransferTemplateCode,
      title: title ?? _template!.name,
      description: description,
      status: ApprovalStatus.pending,
      createdBy: widget.currentUserId,
      paymentDueDate: DateTime.now(),
      formData: dynamicFormData.isEmpty ? null : dynamicFormData,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await widget.createApprovalUseCase.call(
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
        // Закрываем диалог
        Navigator.of(context).pop();

        // Вызываем onSuccess для обновления списка
        widget.onSuccess();

        // Показываем уведомление об успехе
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Согласование перемещения успешно создано'),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Перемещение основных средств'),
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
                if (_isLoadingTemplate)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null && _template == null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  )
                else if (_template != null) ...[
                  FormBuilderTextField(
                    name: 'title',
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                      helperText:
                          'Оставьте пустым, чтобы использовать название из шаблона',
                    ),
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
                  if (_template!.formSchema != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    DynamicBlockForm(
                      key: ValueKey(_template!.code),
                      formSchema: _template!.formSchema,
                      formKey: _formKey,
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
                if (_error != null && _template != null) ...[
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
          onPressed: _isLoading || _template == null ? null : _submit,
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
