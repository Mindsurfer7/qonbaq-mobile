import 'package:flutter/material.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Виджет для динамического рендеринга формы с блоками на основе formSchema
/// Поддерживает условную видимость полей и зависимости между полями
class DynamicBlockForm extends StatefulWidget {
  final Map<String, dynamic>? formSchema;
  final Map<String, dynamic>? initialValues;
  final GlobalKey<FormBuilderState>? formKey;

  const DynamicBlockForm({
    super.key,
    required this.formSchema,
    this.initialValues,
    this.formKey,
  });

  @override
  State<DynamicBlockForm> createState() => _DynamicBlockFormState();
}

class _DynamicBlockFormState extends State<DynamicBlockForm> {
  @override
  Widget build(BuildContext context) {
    if (widget.formSchema == null) {
      return const SizedBox.shrink();
    }

    // Проверяем, есть ли структура с блоками (новый формат)
    final blocks = widget.formSchema!['blocks'] as List<dynamic>?;
    final blocksInfo = widget.formSchema!['blocks_info'] as Map<String, dynamic>?;

    // Если есть блоки, используем новый формат
    if (blocks != null && blocksInfo != null && blocks.isNotEmpty) {
      return _buildBlocksFormat(blocks, blocksInfo);
    }

    // Иначе проверяем, есть ли обычный JSON Schema (старый формат)
    final properties = widget.formSchema!['properties'] as Map<String, dynamic>?;
    if (properties != null && properties.isNotEmpty) {
      return _buildJsonSchemaFormat(properties);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBlocksFormat(List<dynamic> blocks, Map<String, dynamic> blocksInfo) {

    // Если formKey передан, используем его (форма уже создана родителем)
    if (widget.formKey != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: blocks.map((blockName) {
          final blockNameStr = blockName.toString();
          final block = blocksInfo[blockNameStr] as Map<String, dynamic>?;
          if (block == null) return const SizedBox.shrink();

          return UniversalBlock(
            key: ValueKey(blockNameStr),
            blockName: blockNameStr,
            label: block['label'] as String? ?? blockNameStr,
            elements: block['elements'] as List<dynamic>? ?? [],
            formKey: widget.formKey!,
            initialValues: widget.initialValues,
          );
        }).toList(),
      );
    } else {
      // Создаем свою форму (на случай если виджет используется отдельно)
      return FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: blocks.map((blockName) {
            final blockNameStr = blockName.toString();
            final block = blocksInfo[blockNameStr] as Map<String, dynamic>?;
            if (block == null) return const SizedBox.shrink();

            return UniversalBlock(
              key: ValueKey(blockNameStr),
              blockName: blockNameStr,
              label: block['label'] as String? ?? blockNameStr,
              elements: block['elements'] as List<dynamic>? ?? [],
              initialValues: widget.initialValues,
            );
          }).toList(),
        ),
      );
    }
  }

  /// Рендерит форму в формате JSON Schema (старый формат без блоков)
  Widget _buildJsonSchemaFormat(Map<String, dynamic> properties) {
    final required = widget.formSchema!['required'] as List<dynamic>? ?? [];
    final requiredFields = required.map((e) => e.toString()).toSet();

    final fields = <Widget>[];

    properties.forEach((fieldName, fieldSchema) {
      if (fieldSchema is! Map<String, dynamic>) return;

      // Пропускаем processName - бэкенд автоматически удаляет его из formData
      // Можно скрыть поле или оставить только для чтения
      final isProcessName = fieldName == 'processName';

      final fieldType = fieldSchema['type'] as String? ?? 'string';
      final fieldTitle = fieldSchema['title'] as String? ?? fieldName;
      final fieldFormat = fieldSchema['format'] as String?;
      final isRequired = requiredFields.contains(fieldName);
      final defaultValue = fieldSchema['default'];
      final initialValue = widget.initialValues?[fieldName] ?? defaultValue;
      final readOnly = fieldSchema['readOnly'] == true || isProcessName; // processName всегда только для чтения
      final description = fieldSchema['description'] as String?;
      final minLength = fieldSchema['minLength'] as int?;
      final maxLength = fieldSchema['maxLength'] as int?;
      final minimum = fieldSchema['minimum'] as num?;
      final maximum = fieldSchema['maximum'] as num?;
      final enumValues = fieldSchema['enum'] as List<dynamic>?;
      final enumNames = fieldSchema['enumNames'] as List<dynamic>?;
      final options = fieldSchema['options'] as String?;

      Widget field;

      switch (fieldType) {
        case 'string':
        case 'text':
          if (fieldFormat == 'textarea' || fieldFormat == 'text') {
            field = FormBuilderTextField(
              name: fieldName,
              initialValue: initialValue?.toString(),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                helperText: description,
              ),
              maxLines: 4,
              validator: FormBuilderValidators.compose([
                if (isRequired)
                  FormBuilderValidators.required(
                    errorText: 'Поле "$fieldTitle" обязательно',
                  ),
                if (minLength != null)
                  FormBuilderValidators.minLength(
                    minLength,
                    errorText: 'Минимальная длина: $minLength символов',
                  ),
                if (maxLength != null)
                  FormBuilderValidators.maxLength(
                    maxLength,
                    errorText: 'Максимальная длина: $maxLength символов',
                  ),
              ]),
            );
          } else if (fieldFormat == 'select') {
            // Select поле
            if (enumValues != null) {
              final theme = context.appTheme;
              field = FormBuilderDropdown<String>(
                name: fieldName,
                initialValue: initialValue?.toString(),
                enabled: !readOnly,
                decoration: InputDecoration(
                  labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                  border: const OutlineInputBorder(),
                  helperText: description,
                ),
                dropdownColor: theme.backgroundSurface,
                borderRadius: BorderRadius.circular(theme.borderRadius),
                selectedItemBuilder: (BuildContext context) {
                  return enumValues.asMap().entries.map<Widget>((entry) {
                    final index = entry.key;
                    final value = entry.value.toString();
                    final name = enumNames != null && index < enumNames.length
                        ? enumNames[index].toString()
                        : value;
                    return Text(name);
                  }).toList();
                },
                items: enumValues.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value.toString();
                  final name = enumNames != null && index < enumNames.length
                      ? enumNames[index].toString()
                      : value;
                  return createStyledDropdownItem<String>(
                    context: context,
                    value: value,
                    child: Text(name),
                  );
                }).toList(),
                validator: isRequired
                    ? FormBuilderValidators.required(
                        errorText: 'Поле "$fieldTitle" обязательно',
                      )
                    : null,
              );
            } else if (options != null) {
              // Динамический список (departments, projects и т.д.)
              // TODO: Загрузить опции через API
              field = FormBuilderDropdown<String>(
                name: fieldName,
                initialValue: initialValue?.toString(),
                enabled: !readOnly,
                decoration: InputDecoration(
                  labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                  border: const OutlineInputBorder(),
                  helperText: description ?? 'Загрузка опций...',
                ),
                items: const [
                  DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text('Нет доступных опций'),
                  ),
                ],
                validator: isRequired
                    ? FormBuilderValidators.required(
                        errorText: 'Поле "$fieldTitle" обязательно',
                      )
                    : null,
              );
            } else {
              // Обычное текстовое поле
              field = FormBuilderTextField(
                name: fieldName,
                initialValue: initialValue?.toString(),
                enabled: !readOnly,
                decoration: InputDecoration(
                  labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                  border: const OutlineInputBorder(),
                  helperText: description,
                ),
                validator: FormBuilderValidators.compose([
                  if (isRequired)
                    FormBuilderValidators.required(
                      errorText: 'Поле "$fieldTitle" обязательно',
                    ),
                  if (minLength != null)
                    FormBuilderValidators.minLength(
                      minLength,
                      errorText: 'Минимальная длина: $minLength символов',
                    ),
                  if (maxLength != null)
                    FormBuilderValidators.maxLength(
                      maxLength,
                      errorText: 'Максимальная длина: $maxLength символов',
                    ),
                ]),
              );
            }
          } else if (fieldFormat == 'date') {
            DateTime? dateValue;
            if (initialValue is String) {
              dateValue = DateTime.tryParse(initialValue);
            } else if (initialValue is DateTime) {
              dateValue = initialValue;
            }
            field = FormBuilderDateTimePicker(
              name: fieldName,
              initialValue: dateValue,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                helperText: description,
              ),
              inputType: InputType.date,
              validator: isRequired
                  ? FormBuilderValidators.required(
                      errorText: 'Поле "$fieldTitle" обязательно',
                    )
                  : null,
            );
          } else if (fieldFormat == 'datetime') {
            DateTime? dateValue;
            if (initialValue is String) {
              dateValue = DateTime.tryParse(initialValue);
            } else if (initialValue is DateTime) {
              dateValue = initialValue;
            }
            field = FormBuilderDateTimePicker(
              name: fieldName,
              initialValue: dateValue,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.event),
                helperText: description,
              ),
              inputType: InputType.both,
              validator: isRequired
                  ? FormBuilderValidators.required(
                      errorText: 'Поле "$fieldTitle" обязательно',
                    )
                  : null,
            );
          } else if (fieldFormat == 'file') {
            // TODO: Реализовать загрузку файлов
            field = FormBuilderTextField(
              name: fieldName,
              initialValue: initialValue?.toString(),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                helperText: description ?? 'Загрузка файлов будет реализована',
              ),
              validator: isRequired
                  ? FormBuilderValidators.required(
                      errorText: 'Поле "$fieldTitle" обязательно',
                    )
                  : null,
            );
          } else {
            // Обычное текстовое поле
            field = FormBuilderTextField(
              name: fieldName,
              initialValue: initialValue?.toString(),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                helperText: description,
              ),
              validator: FormBuilderValidators.compose([
                if (isRequired)
                  FormBuilderValidators.required(
                    errorText: 'Поле "$fieldTitle" обязательно',
                  ),
                if (minLength != null)
                  FormBuilderValidators.minLength(
                    minLength,
                    errorText: 'Минимальная длина: $minLength символов',
                  ),
                if (maxLength != null)
                  FormBuilderValidators.maxLength(
                    maxLength,
                    errorText: 'Максимальная длина: $maxLength символов',
                  ),
              ]),
            );
          }
          break;

        case 'number':
        case 'integer':
          field = FormBuilderTextField(
            name: fieldName,
            initialValue: initialValue?.toString(),
            enabled: !readOnly,
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
              helperText: description,
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
          break;

        case 'array':
          // TODO: Реализовать массивы
          field = FormBuilderTextField(
            name: fieldName,
            initialValue: initialValue?.toString(),
            enabled: !readOnly,
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
              helperText: description ?? 'Введите значения через запятую',
            ),
            maxLines: 3,
            validator: isRequired
                ? FormBuilderValidators.required(
                    errorText: 'Поле "$fieldTitle" обязательно',
                  )
                : null,
          );
          break;

        default:
          field = FormBuilderTextField(
            name: fieldName,
            initialValue: initialValue?.toString(),
            enabled: !readOnly,
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
              helperText: description,
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

    // Если formKey передан, используем его (форма уже создана родителем)
    if (widget.formKey != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields,
      );
    } else {
      return FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: fields,
        ),
      );
    }
  }
}

/// Виджет для рендеринга блока формы
class UniversalBlock extends StatelessWidget {
  final String blockName;
  final String label;
  final List<dynamic> elements;
  final GlobalKey<FormBuilderState>? formKey;
  final Map<String, dynamic>? initialValues;

  const UniversalBlock({
    super.key,
    required this.blockName,
    required this.label,
    required this.elements,
    this.formKey,
    this.initialValues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Заголовок блока
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Элементы блока
        ...elements.asMap().entries.map((entry) {
          final index = entry.key;
          final element = entry.value as Map<String, dynamic>;
          return ElementFormSwitcher(
            key: ValueKey('$blockName-${element['name']}-$index'),
            element: element,
            blockName: blockName,
            formKey: formKey,
            initialValues: initialValues,
          );
        }),
      ],
    );
  }
}

/// Виджет для рендеринга конкретного элемента формы
class ElementFormSwitcher extends StatefulWidget {
  final Map<String, dynamic> element;
  final String blockName;
  final GlobalKey<FormBuilderState>? formKey;
  final Map<String, dynamic>? initialValues;

  const ElementFormSwitcher({
    super.key,
    required this.element,
    required this.blockName,
    this.formKey,
    this.initialValues,
  });

  @override
  State<ElementFormSwitcher> createState() => _ElementFormSwitcherState();
}

class _ElementFormSwitcherState extends State<ElementFormSwitcher> {
  String get _fieldName {
    return '${widget.blockName}.${widget.element['name']}';
  }

  @override
  Widget build(BuildContext context) {
    // Получаем значения полей, от которых зависит видимость, для реактивности
    final visibilityKey = _getVisibilityKey(context);
    
    // Проверяем видимость элемента
    final isVisible = _checkVisibility(context);
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final elementType = widget.element['type'] as String? ?? 'text';
    final label = widget.element['label'] as String? ?? widget.element['name'];
    final isRequired = widget.element['require'] == true;
    final defaultValue = widget.element['defaultValue'];
    final initialValue = _getInitialValue();

    // Используем key для перестройки виджета при изменении значений, влияющих на видимость
    return KeyedSubtree(
      key: ValueKey('${_fieldName}-$visibilityKey'),
      child: _buildFieldByType(elementType, label, isRequired, defaultValue, initialValue),
    );
  }

  Widget _buildFieldByType(
    String elementType,
    String? label,
    bool isRequired,
    dynamic defaultValue,
    dynamic initialValue,
  ) {
    switch (elementType) {
      case 'text':
        return _buildTextField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
          multiline: widget.element['props']?['multiline'] == true,
        );

      case 'select':
        return _buildSelectField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
          options: widget.element['options'] as List<dynamic>?,
          parent: widget.element['parent'] as String?,
        );

      case 'textarea':
        return _buildTextField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
          multiline: true,
        );

      case 'number':
        return _buildNumberField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
        );

      case 'date':
        return _buildDateField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
        );

      case 'datetime':
        return _buildDateTimeField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
        );

      case 'files':
        // TODO: Реализовать загрузку файлов
        return _buildTextField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
        );

      default:
        return _buildTextField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
        );
    }
  }

  /// Получает ключ для реактивности на основе значений полей, влияющих на видимость
  String _getVisibilityKey(BuildContext context) {
    final props = widget.element['props'] as Map<String, dynamic>?;
    if (props == null) return '';

    final visible = props['visible'] as Map<String, dynamic>?;
    if (visible == null) return '';

    FormBuilderState? formState;
    if (widget.formKey?.currentState != null) {
      formState = widget.formKey!.currentState;
    } else {
      try {
        formState = FormBuilder.of(context);
      } catch (e) {
        return '';
      }
    }

    if (formState == null) return '';

    final formValues = formState.value;
    final flattenedValues = _flattenMap(formValues);

    // Собираем значения всех полей, от которых зависит видимость
    final keys = <String>[];
    for (var fieldPath in visible.keys) {
      final value = _getFieldValue(flattenedValues, fieldPath);
      keys.add('$fieldPath:$value');
    }

    return keys.join('|');
  }

  /// Проверяет видимость элемента на основе условий
  bool _checkVisibility(BuildContext context) {
    final props = widget.element['props'] as Map<String, dynamic>?;
    if (props == null) return true;

    final visible = props['visible'] as Map<String, dynamic>?;
    if (visible == null) return true;

    // Получаем текущие значения формы
    FormBuilderState? formState;
    if (widget.formKey?.currentState != null) {
      formState = widget.formKey!.currentState;
    } else {
      try {
        formState = FormBuilder.of(context);
      } catch (e) {
        // FormBuilder не найден в контексте
        return true;
      }
    }
    
    if (formState == null) return true;

    final formValues = formState.value;
    final flattenedValues = _flattenMap(formValues);

    // Проверяем все условия видимости
    for (var entry in visible.entries) {
      final fieldPath = entry.key;
      final expectedValue = entry.value;

      // Получаем значение поля из формы
      final actualValue = _getFieldValue(flattenedValues, fieldPath);

      // Проверяем условие
      if (expectedValue is String && actualValue is String) {
        // Регулярное выражение
        try {
          final regex = RegExp(expectedValue);
          if (!regex.hasMatch(actualValue)) {
            return false;
          }
        } catch (e) {
          // Если не регулярное выражение, сравниваем как строки
          if (actualValue != expectedValue) {
            return false;
          }
        }
      } else if (actualValue != expectedValue) {
        return false;
      }
    }

    return true;
  }

  /// Получает значение поля из плоского объекта
  dynamic _getFieldValue(Map<String, dynamic> flattenedValues, String fieldPath) {
    // Поддержка путей вида "blocks_new.CheckIn.status"
    final normalizedPath = fieldPath.replaceAll('[', '.').replaceAll(']', '');
    return flattenedValues[normalizedPath] ?? flattenedValues[fieldPath];
  }

  /// Преобразует вложенный объект в плоский
  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, {String prefix = ''}) {
    final result = <String, dynamic>{};
    for (var entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map) {
        result.addAll(_flattenMap(entry.value as Map<String, dynamic>, prefix: key));
      } else if (entry.value is List) {
        // Обработка массивов (например, для deviceCheckPhoto.0.value)
        final list = entry.value as List;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            result.addAll(_flattenMap(list[i] as Map<String, dynamic>, prefix: '$key.$i'));
          } else {
            result['$key.$i'] = list[i];
          }
        }
      } else {
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// Получает начальное значение поля
  dynamic _getInitialValue() {
    if (widget.initialValues == null) return null;
    final flattened = _flattenMap(widget.initialValues!);
    return flattened[_fieldName] ?? flattened[widget.element['name']];
  }

  /// Фильтрует опции на основе значения родительского поля
  List<dynamic> _filterOptions(BuildContext context, List<dynamic>? options, String? parent) {
    if (options == null || parent == null) return options ?? [];

    FormBuilderState? formState;
    if (widget.formKey?.currentState != null) {
      formState = widget.formKey!.currentState;
    } else {
      try {
        formState = FormBuilder.of(context);
      } catch (e) {
        return options;
      }
    }
    
    if (formState == null) return options;

    final formValues = formState.value;
    final flattenedValues = _flattenMap(formValues);

    // Получаем значение родительского поля
    final parentFieldName = '${widget.blockName}.$parent';
    final parentValue = flattenedValues[parentFieldName] ?? flattenedValues[parent];

    if (parentValue == null) return options;

    // Фильтруем опции по parentId
    return options.where((option) {
      if (option is Map<String, dynamic>) {
        final parentId = option['parentId'];
        if (parentId != null) {
          final parentValueNum = num.tryParse(parentValue.toString());
          return parentId == parentValueNum;
        }
      }
      return true;
    }).toList();
  }

  Widget _buildTextField({
    required String? label,
    required bool isRequired,
    dynamic initialValue,
    bool multiline = false,
  }) {
    return FormBuilderTextField(
      name: _fieldName,
      initialValue: initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      maxLines: multiline ? 4 : 1,
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$label" обязательно',
            )
          : null,
    );
  }

  Widget _buildSelectField({
    required String? label,
    required bool isRequired,
    dynamic initialValue,
    List<dynamic>? options,
    String? parent,
  }) {
    // Если есть родительское поле, создаем виджет с реактивностью
    if (parent != null) {
      final parentFieldName = '${widget.blockName}.$parent';
      return _ReactiveSelectField(
        fieldName: _fieldName,
        parentFieldName: parentFieldName,
        label: label,
        isRequired: isRequired,
        initialValue: initialValue?.toString(),
        options: options,
        parent: parent,
        blockName: widget.blockName,
        formKey: widget.formKey,
        filterOptions: _filterOptions,
      );
    }

    // Если нет родительского поля, используем обычный FormBuilderDropdown
    final theme = context.appTheme;
    return FormBuilderDropdown<String>(
      name: _fieldName,
      initialValue: initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      dropdownColor: theme.backgroundSurface,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      selectedItemBuilder: (BuildContext context) {
        return (options ?? []).map<Widget>((option) {
          if (option is Map<String, dynamic>) {
            return Text(option['name']?.toString() ?? option['value']?.toString() ?? '');
          } else {
            return Text(option.toString());
          }
        }).toList();
      },
      items: (options ?? []).isEmpty
          ? [
              const DropdownMenuItem<String>(
                value: null,
                enabled: false,
                child: Text('Нет доступных опций'),
              ),
            ]
          : (options ?? []).map((option) {
              if (option is Map<String, dynamic>) {
                final value = option['value']?.toString();
                if (value == null) {
                  return const DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text('Нет доступных опций'),
                  );
                }
                return createStyledDropdownItem<String>(
                  context: context,
                  value: value,
                  child: Text(option['name']?.toString() ?? value),
                );
              } else {
                return createStyledDropdownItem<String>(
                  context: context,
                  value: option.toString(),
                  child: Text(option.toString()),
                );
              }
            }).toList(),
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$label" обязательно',
            )
          : null,
    );
  }

  Widget _buildNumberField({
    required String? label,
    required bool isRequired,
    dynamic initialValue,
  }) {
    return FormBuilderTextField(
      name: _fieldName,
      initialValue: initialValue?.toString(),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: FormBuilderValidators.compose([
        if (isRequired)
          FormBuilderValidators.required(
            errorText: 'Поле "$label" обязательно',
          ),
        FormBuilderValidators.numeric(
          errorText: 'Введите число',
        ),
      ]),
    );
  }

  Widget _buildDateField({
    required String? label,
    required bool isRequired,
    dynamic initialValue,
  }) {
    DateTime? dateValue;
    if (initialValue is String) {
      dateValue = DateTime.tryParse(initialValue);
    } else if (initialValue is DateTime) {
      dateValue = initialValue;
    }

    return FormBuilderDateTimePicker(
      name: _fieldName,
      initialValue: dateValue,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      inputType: InputType.date,
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$label" обязательно',
            )
          : null,
    );
  }

  Widget _buildDateTimeField({
    required String? label,
    required bool isRequired,
    dynamic initialValue,
  }) {
    DateTime? dateValue;
    if (initialValue is String) {
      dateValue = DateTime.tryParse(initialValue);
    } else if (initialValue is DateTime) {
      dateValue = initialValue;
    }

    return FormBuilderDateTimePicker(
      name: _fieldName,
      initialValue: dateValue,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.event),
      ),
      inputType: InputType.both,
      validator: isRequired
          ? FormBuilderValidators.required(
              errorText: 'Поле "$label" обязательно',
            )
          : null,
    );
  }
}

/// Реактивный виджет для select поля с зависимостью от родительского поля
class _ReactiveSelectField extends StatefulWidget {
  final String fieldName;
  final String parentFieldName;
  final String? label;
  final bool isRequired;
  final String? initialValue;
  final List<dynamic>? options;
  final String? parent;
  final String blockName;
  final GlobalKey<FormBuilderState>? formKey;
  final List<dynamic> Function(BuildContext, List<dynamic>?, String?) filterOptions;

  const _ReactiveSelectField({
    required this.fieldName,
    required this.parentFieldName,
    this.label,
    required this.isRequired,
    this.initialValue,
    this.options,
    this.parent,
    required this.blockName,
    this.formKey,
    required this.filterOptions,
  });

  @override
  State<_ReactiveSelectField> createState() => _ReactiveSelectFieldState();
}

class _ReactiveSelectFieldState extends State<_ReactiveSelectField> {
  @override
  Widget build(BuildContext context) {
    return FormBuilderField<String>(
      name: widget.fieldName,
      initialValue: widget.initialValue,
      builder: (FormFieldState<String> field) {
        // Получаем текущее значение родительского поля
        FormBuilderState? formState;
        if (widget.formKey?.currentState != null) {
          formState = widget.formKey!.currentState;
        } else {
          try {
            formState = FormBuilder.of(context);
          } catch (e) {
            // FormBuilder не найден
          }
        }

        // Получаем значение родительского поля для фильтрации
        String? parentValue;
        if (formState != null) {
          final formValues = formState.value;
          final flattenedValues = _flattenMap(formValues);
          parentValue = flattenedValues[widget.parentFieldName]?.toString();
        }

        // Фильтруем опции на основе значения родителя
        final currentOptions = widget.filterOptions(context, widget.options, widget.parent);

        // Используем key для перестройки виджета при изменении родительского значения
        final theme = context.appTheme;
        return FormBuilderDropdown<String>(
          key: ValueKey('${widget.fieldName}-$parentValue'),
          name: widget.fieldName,
          initialValue: field.value,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.label} *' : widget.label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          dropdownColor: theme.backgroundSurface,
          borderRadius: BorderRadius.circular(theme.borderRadius),
          selectedItemBuilder: (BuildContext context) {
            return currentOptions.map<Widget>((option) {
              if (option is Map<String, dynamic>) {
                return Text(option['name']?.toString() ?? option['value']?.toString() ?? '');
              } else {
                return Text(option.toString());
              }
            }).toList();
          },
          items: currentOptions.isEmpty
              ? [
                  const DropdownMenuItem<String>(
                    value: null,
                    enabled: false,
                    child: Text('Нет доступных опций'),
                  ),
                ]
              : currentOptions.map((option) {
                  if (option is Map<String, dynamic>) {
                    final value = option['value']?.toString();
                    if (value == null) {
                      return const DropdownMenuItem<String>(
                        value: null,
                        enabled: false,
                        child: Text('Нет доступных опций'),
                      );
                    }
                    return createStyledDropdownItem<String>(
                      context: context,
                      value: value,
                      child: Text(option['name']?.toString() ?? value),
                    );
                  } else {
                    return createStyledDropdownItem<String>(
                      context: context,
                      value: option.toString(),
                      child: Text(option.toString()),
                    );
                  }
                }).toList(),
          onChanged: (value) {
            field.didChange(value);
          },
          validator: widget.isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Поле "${widget.label}" обязательно';
                  }
                  return null;
                }
              : null,
        );
      },
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Поле "${widget.label}" обязательно';
              }
              return null;
            }
          : null,
    );
  }

  Map<String, dynamic> _flattenMap(Map<String, dynamic> map, {String prefix = ''}) {
    final result = <String, dynamic>{};
    for (var entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (entry.value is Map) {
        result.addAll(_flattenMap(entry.value as Map<String, dynamic>, prefix: key));
      } else if (entry.value is List) {
        final list = entry.value as List;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            result.addAll(_flattenMap(list[i] as Map<String, dynamic>, prefix: '$key.$i'));
          } else {
            result['$key.$i'] = list[i];
          }
        }
      } else {
        result[key] = entry.value;
      }
    }
    return result;
  }
}

