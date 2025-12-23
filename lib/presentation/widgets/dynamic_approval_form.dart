import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/approval_template.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';

/// Виджет для динамического рендеринга формы согласования на основе formSchema
class DynamicApprovalForm extends StatefulWidget {
  final Map<String, dynamic>? formSchema;
  final Map<String, dynamic>? initialValues;
  final GlobalKey<FormBuilderState>? formKey;

  const DynamicApprovalForm({
    super.key,
    required this.formSchema,
    this.initialValues,
    this.formKey,
  });

  @override
  State<DynamicApprovalForm> createState() => _DynamicApprovalFormState();
}

class _DynamicApprovalFormState extends State<DynamicApprovalForm> {
  Map<String, dynamic>? _projectsList;
  bool _isLoadingProjects = false;

  @override
  void initState() {
    super.initState();
    // Загружаем динамические списки, если они нужны
    _loadDynamicOptions();
  }

  @override
  void didUpdateWidget(DynamicApprovalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если formSchema изменился, перезагружаем опции и очищаем форму
    if (oldWidget.formSchema != widget.formSchema) {
      // Очищаем значения полей формы, которые относятся к старому шаблону
      if (widget.formKey?.currentState != null && oldWidget.formSchema != null) {
        final oldProperties = oldWidget.formSchema!['properties'] as Map<String, dynamic>?;
        if (oldProperties != null) {
          for (var fieldName in oldProperties.keys) {
            // Очищаем только поля из старого шаблона
            widget.formKey?.currentState?.fields[fieldName]?.didChange(null);
          }
        }
      }
      // Перезагружаем опции для нового шаблона
      _loadDynamicOptions();
    }
  }

  Future<void> _loadDynamicOptions() async {
    if (widget.formSchema == null) return;

    final properties = widget.formSchema!['properties'] as Map<String, dynamic>?;
    if (properties == null) return;

    // Проверяем, нужны ли проекты
    bool needsProjects = false;
    for (var property in properties.values) {
      if (property is Map<String, dynamic>) {
        if (property['format'] == 'select' && property['options'] == 'projects') {
          needsProjects = true;
          break;
        }
      }
    }

    if (needsProjects) {
      // TODO: Загрузить список проектов через API
      // Пока оставляем пустым
      setState(() {
        _projectsList = {};
        _isLoadingProjects = false;
      });
    }
  }

  List<Widget> _buildFormFields() {
    if (widget.formSchema == null) {
      return [];
    }

    final properties = widget.formSchema!['properties'] as Map<String, dynamic>?;
    if (properties == null || properties.isEmpty) {
      return [];
    }

    final required = widget.formSchema!['required'] as List<dynamic>? ?? [];
    final requiredFields = required.map((e) => e.toString()).toSet();

    final fields = <Widget>[];

    properties.forEach((fieldName, fieldSchema) {
      if (fieldSchema is! Map<String, dynamic>) return;

      final fieldType = fieldSchema['type'] as String? ?? 'string';
      final fieldTitle = fieldSchema['title'] as String? ?? fieldName;
      final fieldFormat = fieldSchema['format'] as String?;
      final isRequired = requiredFields.contains(fieldName);
      final defaultValue = fieldSchema['default'];
      final initialValue = widget.initialValues?[fieldName] ?? defaultValue;

      Widget field;

      switch (fieldType) {
        case 'string':
          field = _buildStringField(
            fieldName: fieldName,
            fieldTitle: fieldTitle,
            fieldFormat: fieldFormat,
            isRequired: isRequired,
            initialValue: initialValue,
            fieldSchema: fieldSchema,
          );
          break;

        case 'number':
          field = _buildNumberField(
            fieldName: fieldName,
            fieldTitle: fieldTitle,
            isRequired: isRequired,
            initialValue: initialValue,
            fieldSchema: fieldSchema,
          );
          break;

        case 'array':
          field = _buildArrayField(
            fieldName: fieldName,
            fieldTitle: fieldTitle,
            isRequired: isRequired,
            initialValue: initialValue,
            fieldSchema: fieldSchema,
          );
          break;

        default:
          // По умолчанию текстовое поле
          field = FormBuilderTextField(
            name: fieldName,
            initialValue: initialValue?.toString(),
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
            ),
            validator: isRequired
                ? FormBuilderValidators.required(
                    errorText: 'Поле "$fieldTitle" обязательно',
                  )
                : null,
          );
      }

      fields.add(field);
      fields.add(const SizedBox(height: 16));
    });

    return fields;
  }

  Widget _buildStringField({
    required String fieldName,
    required String fieldTitle,
    String? fieldFormat,
    required bool isRequired,
    dynamic initialValue,
    required Map<String, dynamic> fieldSchema,
  }) {
    switch (fieldFormat) {
      case 'textarea':
        return FormBuilderTextField(
          name: fieldName,
          initialValue: initialValue?.toString(),
          decoration: InputDecoration(
            labelText: isRequired ? '$fieldTitle *' : fieldTitle,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: isRequired
              ? FormBuilderValidators.required(
                  errorText: 'Поле "$fieldTitle" обязательно',
                )
              : null,
        );

      case 'select':
        return _buildSelectField(
          fieldName: fieldName,
          fieldTitle: fieldTitle,
          isRequired: isRequired,
          initialValue: initialValue,
          fieldSchema: fieldSchema,
        );

      case 'datetime':
        return FormBuilderDateTimePicker(
          name: fieldName,
          initialValue: initialValue is String
              ? DateTime.tryParse(initialValue)
              : initialValue is DateTime
                  ? initialValue
                  : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$fieldTitle *' : fieldTitle,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.event),
          ),
          inputType: InputType.both,
          format: null, // Используем формат по умолчанию
          validator: isRequired
              ? FormBuilderValidators.required(
                  errorText: 'Поле "$fieldTitle" обязательно',
                )
              : null,
        );

      case 'date':
        return FormBuilderDateTimePicker(
          name: fieldName,
          initialValue: initialValue is String
              ? DateTime.tryParse(initialValue)
              : initialValue is DateTime
                  ? initialValue
                  : null,
          decoration: InputDecoration(
            labelText: isRequired ? '$fieldTitle *' : fieldTitle,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          inputType: InputType.date,
          format: null, // Используем формат по умолчанию
          validator: isRequired
              ? FormBuilderValidators.required(
                  errorText: 'Поле "$fieldTitle" обязательно',
                )
              : null,
        );

      default:
        // Обычное текстовое поле
        return FormBuilderTextField(
          name: fieldName,
          initialValue: initialValue?.toString(),
          decoration: InputDecoration(
            labelText: isRequired ? '$fieldTitle *' : fieldTitle,
            border: const OutlineInputBorder(),
          ),
          validator: isRequired
              ? FormBuilderValidators.required(
                  errorText: 'Поле "$fieldTitle" обязательно',
                )
              : null,
        );
    }
  }

  Widget _buildSelectField({
    required String fieldName,
    required String fieldTitle,
    required bool isRequired,
    dynamic initialValue,
    required Map<String, dynamic> fieldSchema,
  }) {
    final options = fieldSchema['options'] as String?;

    // Если это динамический список (например, "projects")
    if (options == 'projects') {
      if (_isLoadingProjects) {
        return FormBuilderDropdown<String>(
          name: fieldName,
          decoration: InputDecoration(
            labelText: isRequired ? '$fieldTitle *' : fieldTitle,
            border: const OutlineInputBorder(),
            suffixIcon: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          items: const [],
          validator: isRequired
              ? FormBuilderValidators.required(
                  errorText: 'Поле "$fieldTitle" обязательно',
                )
              : null,
        );
      }

      // TODO: Загрузить проекты через API
      // Пока используем пустой список
      final projectItems = (_projectsList ?? {}).entries.map((entry) {
        return createStyledDropdownItem<String>(
          context: context,
          value: entry.key,
          child: Text(entry.value.toString()),
        );
      }).toList();

      final theme = context.appTheme;
      return FormBuilderDropdown<String>(
        name: fieldName,
        initialValue: initialValue?.toString(),
        decoration: InputDecoration(
          labelText: isRequired ? '$fieldTitle *' : fieldTitle,
          border: const OutlineInputBorder(),
        ),
        dropdownColor: theme.backgroundSurface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        items: projectItems.isEmpty
            ? [
                const DropdownMenuItem<String>(
                  value: null,
                  enabled: false,
                  child: Text('Нет доступных проектов'),
                ),
              ]
            : projectItems,
        validator: isRequired
            ? FormBuilderValidators.required(
                errorText: 'Поле "$fieldTitle" обязательно',
              )
            : null,
      );
    }

    // Если это статический список опций
    final staticOptions = fieldSchema['enum'] as List<dynamic>?;
    if (staticOptions != null) {
      final theme = context.appTheme;
      return FormBuilderDropdown<String>(
        name: fieldName,
        initialValue: initialValue?.toString(),
        decoration: InputDecoration(
          labelText: isRequired ? '$fieldTitle *' : fieldTitle,
          border: const OutlineInputBorder(),
        ),
        dropdownColor: theme.backgroundSurface,
        borderRadius: BorderRadius.circular(theme.borderRadius),
        items: staticOptions.map((option) {
          return createStyledDropdownItem<String>(
            context: context,
            value: option.toString(),
            child: Text(option.toString()),
          );
        }).toList(),
        validator: isRequired
            ? FormBuilderValidators.required(
                errorText: 'Поле "$fieldTitle" обязательно',
              )
            : null,
      );
    }

    // Если опции не указаны, возвращаем обычное текстовое поле
    return FormBuilderTextField(
      name: fieldName,
      initialValue: initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$fieldTitle *' : fieldTitle,
        border: const OutlineInputBorder(),
      ),
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$fieldTitle" обязательно',
            )
          : null,
    );
  }

  Widget _buildNumberField({
    required String fieldName,
    required String fieldTitle,
    required bool isRequired,
    dynamic initialValue,
    required Map<String, dynamic> fieldSchema,
  }) {
    final minimum = fieldSchema['minimum'] as num?;
    final maximum = fieldSchema['maximum'] as num?;

    return FormBuilderTextField(
      name: fieldName,
      initialValue: initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$fieldTitle *' : fieldTitle,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: FormBuilderValidators.compose([
        if (isRequired)
          FormBuilderValidators.required(
            errorText: 'Поле "$fieldTitle" обязательно',
          ),
        FormBuilderValidators.numeric(
          errorText: 'Введите число',
        ),
        if (minimum != null)
          FormBuilderValidators.min(
            minimum,
            errorText: 'Значение должно быть не менее $minimum',
          ),
        if (maximum != null)
          FormBuilderValidators.max(
            maximum,
            errorText: 'Значение должно быть не более $maximum',
          ),
      ]),
    );
  }

  Widget _buildArrayField({
    required String fieldName,
    required String fieldTitle,
    required bool isRequired,
    dynamic initialValue,
    required Map<String, dynamic> fieldSchema,
  }) {
    // Для массивов пока используем текстовое поле с разделителями
    // Можно расширить позже для более сложных случаев
    // final items = fieldSchema['items'] as Map<String, dynamic>?;
    // final itemType = items?['type'] as String? ?? 'string';

    return FormBuilderTextField(
      name: fieldName,
      initialValue: initialValue is List
          ? initialValue.join(', ')
          : initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$fieldTitle *' : fieldTitle,
        border: const OutlineInputBorder(),
        helperText: 'Введите значения через запятую',
      ),
      maxLines: 3,
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$fieldTitle" обязательно',
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.formSchema == null) {
      return const SizedBox.shrink();
    }

    final fields = _buildFormFields();
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }

    // Если formKey передан, используем его (форма уже создана родителем)
    // Иначе создаем вложенную форму (не рекомендуется, но на случай если нужно)
    if (widget.formKey != null) {
      // Форма уже создана родителем, просто возвращаем поля
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields,
      );
    } else {
      // Создаем свою форму (на случай если виджет используется отдельно)
      return FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: fields,
        ),
      );
    }
  }
}

/// Вспомогательная функция для получения данных формы
/// Возвращает только данные из динамической формы (исключая системные поля)
Map<String, dynamic>? getFormData(GlobalKey<FormBuilderState> formKey) {
  if (formKey.currentState == null) {
    return null;
  }

  if (!formKey.currentState!.validate()) {
    return null;
  }

  final formValues = formKey.currentState!.value;
  final formData = <String, dynamic>{};

  // Преобразуем значения формы в нужный формат
  // Исключаем системные поля (template, title, description)
  formValues.forEach((key, value) {
    if (value != null && key != 'template' && key != 'title' && key != 'description') {
      // Если это DateTime, преобразуем в ISO строку
      if (value is DateTime) {
        formData[key] = value.toIso8601String();
      } else if (value is ApprovalTemplate) {
        // Пропускаем объекты шаблонов
      } else {
        formData[key] = value;
      }
    }
  });

  return formData;
}

