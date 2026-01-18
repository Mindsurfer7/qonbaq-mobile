import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/usecases/get_fixed_assets.dart';
import '../../domain/usecases/create_fixed_asset.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';
import '../providers/department_provider.dart';
import '../widgets/create_fixed_asset_form.dart';
import '../widgets/fixed_asset_card.dart';
import '../../core/theme/theme_extensions.dart';

/// Страница основных средств
class FixedAssetsPage extends StatefulWidget {
  const FixedAssetsPage({super.key});

  @override
  State<FixedAssetsPage> createState() => _FixedAssetsPageState();
}

const int _pageLimit = 20;

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
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) return;
    final businessId = selectedBusiness.id;
    Provider.of<ProjectProvider>(context, listen: false).loadProjects(businessId);
    Provider.of<DepartmentProvider>(context, listen: false).loadDepartments(businessId);
    _loadEmployees(businessId);
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
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() => _error = 'Компания не выбрана');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getFixedAssetsUseCase = Provider.of<GetFixedAssets>(context, listen: false);
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
          _error = failure.message.isNotEmpty
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
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createFixedAssetUseCase = Provider.of<CreateFixedAsset>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) return;

    showDialog(
      context: context,
      builder: (context) => _CreateFixedAssetDialog(
        businessId: selectedBusiness.id,
        userRepository: userRepository,
        createFixedAssetUseCase: createFixedAssetUseCase,
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssets,
          ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: "create_fixed_asset",
        onPressed: _showCreateAssetDialog,
        backgroundColor: context.appTheme.accentPrimary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
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

    if (_assets.isEmpty) {
      return const Center(child: Text('Нет основных средств'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _assets.length,
            itemBuilder: (context, index) {
              final asset = _assets[index];
              return FixedAssetCard(
                asset: asset,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/business/admin/fixed_assets/detail',
                    arguments: asset.id,
                  );
                },
              );
            },
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
              (t) => DropdownMenuItem(
                value: t,
                child: Text(_getAssetTypeName(t)),
              ),
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
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Сбросить'),
            ),
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
  State<_CreateFixedAssetDialog> createState() => _CreateFixedAssetDialogState();
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
