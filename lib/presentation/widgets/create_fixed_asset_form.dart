import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/models/validation_error.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/project_provider.dart';
import '../providers/department_provider.dart';
import 'user_selector_widget.dart';

/// Форма создания или редактирования основного средства
class CreateFixedAssetForm extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final Function(FixedAsset) onSubmit;
  final VoidCallback onCancel;
  final String? error;
  final List<ValidationError>? validationErrors;
  final Function(String)? onError;
  /// При задании — режим редактирования (владелец скрыт, кнопка «Сохранить»)
  final FixedAsset? initialAsset;

  const CreateFixedAssetForm({
    super.key,
    required this.businessId,
    required this.userRepository,
    required this.onSubmit,
    required this.onCancel,
    this.error,
    this.validationErrors,
    this.onError,
    this.initialAsset,
  });

  @override
  State<CreateFixedAssetForm> createState() => _CreateFixedAssetFormState();
}

class _CreateFixedAssetFormState extends State<CreateFixedAssetForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _selectedOwnerId;
  String? _selectedProjectId;
  String? _selectedDepartmentId;
  Map<String, String> _fieldErrors = {};

  @override
  void didUpdateWidget(CreateFixedAssetForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.validationErrors != null &&
        widget.validationErrors!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyValidationErrors();
      });
    } else if (widget.validationErrors == null ||
        widget.validationErrors!.isEmpty) {
      setState(() {
        _fieldErrors.clear();
      });
    }
  }

  void _applyValidationErrors() {
    final errors = <String, String>{};
    if (widget.validationErrors != null) {
      for (final error in widget.validationErrors!) {
        errors[error.field] = error.message;
      }
    }
    setState(() {
      _fieldErrors = errors;
    });

    // Устанавливаем ошибки в поля формы
    if (_formKey.currentState != null) {
      for (final entry in errors.entries) {
        _formKey.currentState?.fields[entry.key]?.didChange(null);
        _formKey.currentState?.fields[entry.key]
            ?.invalidate(entry.value);
      }
    }
  }

  void _loadInitialData() {
    final projectProvider = Provider.of<ProjectProvider>(
      context,
      listen: false,
    );
    final departmentProvider = Provider.of<DepartmentProvider>(
      context,
      listen: false,
    );

    projectProvider.loadProjects(widget.businessId);
    departmentProvider.loadDepartments(widget.businessId);
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialAsset != null) {
      _selectedProjectId = widget.initialAsset!.projectId;
      _selectedDepartmentId = widget.initialAsset!.departmentId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

  void _handleSubmit() {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final now = DateTime.now();
      final creationDate = formData['creationDate'] as DateTime? ?? now;
      final a = widget.initialAsset;

      if (a != null) {
        final asset = FixedAsset(
          id: a.id,
          businessId: a.businessId,
          projectId: _selectedProjectId,
          name: formData['name'] as String,
          model: formData['model'] as String?,
          type: formData['type'] as AssetType,
          inventoryNumber: formData['inventoryNumber'] as String?,
          serialNumber: formData['serialNumber'] as String?,
          locationCity: formData['locationCity'] as String?,
          locationAddress: formData['locationAddress'] as String?,
          condition: formData['condition'] as AssetCondition,
          departmentId: _selectedDepartmentId,
          currentOwnerId: a.currentOwnerId,
          creationDate: creationDate,
          createdAt: a.createdAt,
          updatedAt: now,
          archivedAt: a.archivedAt,
          currentOwner: a.currentOwner,
          department: a.department,
          project: a.project,
          repairsCount: a.repairsCount,
          photosCount: a.photosCount,
          tasksCount: a.tasksCount,
          writeOff: a.writeOff,
          transfers: a.transfers,
          repairs: a.repairs,
          photos: a.photos,
          inventories: a.inventories,
          repairsTotal: a.repairsTotal,
        );
        widget.onSubmit(asset);
        return;
      }

      final asset = FixedAsset(
        id: '',
        businessId: widget.businessId,
        projectId: _selectedProjectId,
        name: formData['name'] as String,
        model: formData['model'] as String?,
        type: formData['type'] as AssetType,
        inventoryNumber: formData['inventoryNumber'] as String?,
        serialNumber: formData['serialNumber'] as String?,
        locationCity: formData['locationCity'] as String?,
        locationAddress: formData['locationAddress'] as String?,
        condition: formData['condition'] as AssetCondition,
        departmentId: _selectedDepartmentId,
        currentOwnerId: _selectedOwnerId ?? '',
        creationDate: creationDate,
        createdAt: now,
        updatedAt: now,
      );
      widget.onSubmit(asset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: FormBuilder(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Общая ошибка
            if (widget.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Название *
            FormBuilderTextField(
              name: 'name',
              initialValue: widget.initialAsset?.name,
              decoration: InputDecoration(
                labelText: 'Название *',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['name'],
                errorMaxLines: 2,
              ),
              validator: FormBuilderValidators.required(
                errorText: 'Название обязательно',
              ),
            ),
            const SizedBox(height: 16),

            // Тип *
            FormBuilderDropdown<AssetType>(
              name: 'type',
              decoration: InputDecoration(
                labelText: 'Тип *',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['type'],
                errorMaxLines: 2,
              ),
              initialValue: widget.initialAsset?.type ?? AssetType.other,
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(
                context.appTheme.borderRadius,
              ),
              selectedItemBuilder: (BuildContext context) {
                return AssetType.values.map<Widget>((AssetType type) {
                  return Text(_getAssetTypeName(type));
                }).toList();
              },
              items: AssetType.values
                  .map(
                    (type) => createStyledDropdownItem<AssetType>(
                      context: context,
                      value: type,
                      child: Text(_getAssetTypeName(type)),
                    ),
                  )
                  .toList(),
              validator: FormBuilderValidators.required(
                errorText: 'Тип обязателен',
              ),
            ),
            const SizedBox(height: 16),

            // Состояние *
            FormBuilderDropdown<AssetCondition>(
              name: 'condition',
              decoration: InputDecoration(
                labelText: 'Состояние *',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['condition'],
                errorMaxLines: 2,
              ),
              initialValue: widget.initialAsset?.condition ?? AssetCondition.good,
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(
                context.appTheme.borderRadius,
              ),
              selectedItemBuilder: (BuildContext context) {
                return AssetCondition.values.map<Widget>((AssetCondition condition) {
                  return Text(_getAssetConditionName(condition));
                }).toList();
              },
              items: AssetCondition.values
                  .map(
                    (condition) => createStyledDropdownItem<AssetCondition>(
                      context: context,
                      value: condition,
                      child: Text(_getAssetConditionName(condition)),
                    ),
                  )
                  .toList(),
              validator: FormBuilderValidators.required(
                errorText: 'Состояние обязательно',
              ),
            ),
            const SizedBox(height: 16),

            // Модель
            FormBuilderTextField(
              name: 'model',
              initialValue: widget.initialAsset?.model,
              decoration: InputDecoration(
                labelText: 'Модель',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['model'],
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Инвентарный номер
            FormBuilderTextField(
              name: 'inventoryNumber',
              initialValue: widget.initialAsset?.inventoryNumber,
              decoration: InputDecoration(
                labelText: 'Инвентарный номер',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['inventoryNumber'],
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Серийный номер
            FormBuilderTextField(
              name: 'serialNumber',
              initialValue: widget.initialAsset?.serialNumber,
              decoration: InputDecoration(
                labelText: 'Серийный номер',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['serialNumber'],
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Город
            FormBuilderTextField(
              name: 'locationCity',
              initialValue: widget.initialAsset?.locationCity,
              decoration: InputDecoration(
                labelText: 'Город',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['locationCity'],
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Адрес
            FormBuilderTextField(
              name: 'locationAddress',
              initialValue: widget.initialAsset?.locationAddress,
              decoration: InputDecoration(
                labelText: 'Адрес',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['locationAddress'],
                errorMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),

            // Проект
            FormBuilderDropdown<String?>(
              name: 'projectId',
              decoration: InputDecoration(
                labelText: 'Проект',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['projectId'],
                errorMaxLines: 2,
              ),
              initialValue: _selectedProjectId,
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(
                context.appTheme.borderRadius,
              ),
              selectedItemBuilder: (BuildContext context) {
                return [
                  const Text('Не выбран'),
                  ...(projectProvider.projects ?? [])
                      .map((project) => Text(project.name)),
                ];
              },
              items: [
                createStyledDropdownItem<String?>(
                  context: context,
                  value: null,
                  child: const Text('Не выбран'),
                ),
                ...(projectProvider.projects ?? [])
                    .map(
                      (project) => createStyledDropdownItem<String?>(
                        context: context,
                        value: project.id,
                        child: Text(project.name),
                      ),
                    ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Подразделение
            FormBuilderDropdown<String?>(
              name: 'departmentId',
              decoration: InputDecoration(
                labelText: 'Подразделение',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['departmentId'],
                errorMaxLines: 2,
              ),
              initialValue: _selectedDepartmentId,
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(
                context.appTheme.borderRadius,
              ),
              selectedItemBuilder: (BuildContext context) {
                return [
                  const Text('Не выбрано'),
                  ...(departmentProvider.departments ?? [])
                      .map((department) => Text(department.name)),
                ];
              },
              items: [
                createStyledDropdownItem<String?>(
                  context: context,
                  value: null,
                  child: const Text('Не выбрано'),
                ),
                ...(departmentProvider.departments ?? [])
                    .map(
                      (department) => createStyledDropdownItem<String?>(
                        context: context,
                        value: department.id,
                        child: Text(department.name),
                      ),
                    ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDepartmentId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Владелец (только при создании; при редактировании — через «Передать»)
            if (widget.initialAsset == null)
              UserSelectorWidget(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                selectedUserId: _selectedOwnerId,
                onUserSelected: (userId) {
                  setState(() {
                    _selectedOwnerId = userId;
                  });
                },
                label: 'Владелец',
                required: false,
              ),
            if (widget.initialAsset == null) const SizedBox(height: 16),

            // Дата создания
            FormBuilderDateTimePicker(
              name: 'creationDate',
              decoration: InputDecoration(
                labelText: 'Дата создания',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                errorText: _fieldErrors['creationDate'],
                errorMaxLines: 2,
              ),
              initialValue: widget.initialAsset?.creationDate ?? DateTime.now(),
              inputType: InputType.date,
            ),
            const SizedBox(height: 24),

            // Кнопки
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Отмена'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(widget.initialAsset != null ? 'Сохранить' : 'Создать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}