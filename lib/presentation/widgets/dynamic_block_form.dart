import 'package:flutter/material.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Callback для уведомления об изменениях полей формы
typedef OnFieldChanged = void Function(String fieldName, dynamic value);

/// Виджет для динамического рендеринга формы с блоками на основе formSchema
/// Поддерживает условную видимость полей и зависимости между полями
class DynamicBlockForm extends StatefulWidget {
  final Map<String, dynamic>? formSchema;
  final Map<String, dynamic>? initialValues;
  final GlobalKey<FormBuilderState>? formKey;
  final bool
  isEditMode; // Режим редактирования - без валидации обязательных полей

  const DynamicBlockForm({
    super.key,
    required this.formSchema,
    this.initialValues,
    this.formKey,
    this.isEditMode = false,
  });

  @override
  State<DynamicBlockForm> createState() => _DynamicBlockFormState();
}

class _DynamicBlockFormState extends State<DynamicBlockForm> {
  /// Локальное хранилище значений полей для реактивности
  /// Это решает проблему timing - FormBuilderState.value может быть не обновлён
  /// в момент вызова onChanged
  final Map<String, dynamic> _localFieldValues = {};

  /// Флаг для отслеживания, был ли вызван dispose
  bool _isDisposed = false;

  /// Флаг для предотвращения циклических обновлений
  bool _isUpdatingFields = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void didUpdateWidget(DynamicBlockForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Если formSchema изменился, очищаем локальное хранилище значений
    if (oldWidget.formSchema != widget.formSchema) {
      _localFieldValues.clear();
      _isUpdatingFields = false;
    }
  }

  /// Обработчик изменения полей формы - перестраивает виджет для обновления видимости
  void _handleFieldChanged(String fieldName, dynamic value) {
    // Проверяем, что виджет не disposed
    if (_isDisposed || !mounted) return;

    // Если идет обновление полей программно, не обрабатываем изменения
    if (_isUpdatingFields) return;

    // Проверяем, действительно ли значение изменилось
    final oldValue = _localFieldValues[fieldName];
    if (oldValue == value) {
      // Значение не изменилось, не нужно обновлять
      return;
    }

    // Обновляем локальное хранилище
    _localFieldValues[fieldName] = value;

    // Используем addPostFrameCallback чтобы дать FormBuilder время обновить свой state
    // Но только если виджет еще mounted
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted && !_isUpdatingFields) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.formSchema == null) {
      return const SizedBox.shrink();
    }

    // Проверяем, есть ли структура с блоками (новый формат)
    final blocksValue = widget.formSchema!['blocks'];
    final List<dynamic>? blocks =
        blocksValue is List
            ? blocksValue
            : null; // Если blocks не список, это не новый формат
    final blocksInfoValue = widget.formSchema!['blocks_info'];
    final Map<String, dynamic>? blocksInfo =
        blocksInfoValue is Map
            ? Map<String, dynamic>.from(blocksInfoValue)
            : null;

    // Если есть блоки, используем новый формат
    if (blocks != null && blocksInfo != null && blocks.isNotEmpty) {
      return _buildBlocksFormat(blocks, blocksInfo);
    }

    // Иначе проверяем, есть ли обычный JSON Schema (старый формат)
    final propertiesValue = widget.formSchema!['properties'];
    final Map<String, dynamic>? properties =
        propertiesValue is Map
            ? Map<String, dynamic>.from(propertiesValue)
            : null;
    if (properties != null && properties.isNotEmpty) {
      return _buildJsonSchemaFormat(properties);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBlocksFormat(
    List<dynamic> blocks,
    Map<String, dynamic> blocksInfo,
  ) {
    // Если formKey передан, используем его (форма уже создана родителем)
    if (widget.formKey != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:
            blocks.asMap().entries.map((entry) {
              final index = entry.key;
              final blockName = entry.value;
              final blockNameStr = blockName.toString();
              final blockValue = blocksInfo[blockNameStr];
              final Map<String, dynamic>? block =
                  blockValue is Map ? blockValue as Map<String, dynamic> : null;
              if (block == null) return const SizedBox.shrink();

              final isLast = index == blocks.length - 1;
              final elementsValue = block['elements'];
              final List<dynamic> elements =
                  elementsValue is List
                      ? elementsValue
                      : []; // Если elements не список, используем пустой список
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UniversalBlock(
                    key: ValueKey(blockNameStr),
                    blockName: blockNameStr,
                    label: block['label'] as String? ?? blockNameStr,
                    elements: elements,
                    formKey: widget.formKey!,
                    initialValues: widget.initialValues,
                    onFieldChanged: _handleFieldChanged,
                    localFieldValues: _localFieldValues,
                    isEditMode: widget.isEditMode,
                  ),
                  if (!isLast) const SizedBox(height: 16),
                ],
              );
            }).toList(),
      );
    } else {
      // Создаем свою форму (на случай если виджет используется отдельно)
      return FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              blocks.asMap().entries.map((entry) {
                final index = entry.key;
                final blockName = entry.value;
                final blockNameStr = blockName.toString();
                final blockValue = blocksInfo[blockNameStr];
                final Map<String, dynamic>? block =
                    blockValue is Map
                        ? blockValue as Map<String, dynamic>
                        : null;
                if (block == null) return const SizedBox.shrink();

                final isLast = index == blocks.length - 1;
                final elementsValue = block['elements'];
                final List<dynamic> elements =
                    elementsValue is List
                        ? elementsValue
                        : []; // Если elements не список, используем пустой список
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    UniversalBlock(
                      key: ValueKey(blockNameStr),
                      blockName: blockNameStr,
                      label: block['label'] as String? ?? blockNameStr,
                      elements: elements,
                      initialValues: widget.initialValues,
                      onFieldChanged: _handleFieldChanged,
                      localFieldValues: _localFieldValues,
                      isEditMode: widget.isEditMode,
                    ),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                );
              }).toList(),
        ),
      );
    }
  }

  /// Рендерит форму в формате JSON Schema (старый формат без блоков)
  Widget _buildJsonSchemaFormat(Map<String, dynamic> properties) {
    final requiredValue = widget.formSchema!['required'];
    final List<dynamic> required = requiredValue is List ? requiredValue : [];
    final requiredFields = required.map((e) => e.toString()).toSet();

    final fields = <Widget>[];

    properties.forEach((fieldName, fieldSchema) {
      if (fieldSchema is! Map<String, dynamic>) return;

      // Пропускаем processName - бэкенд автоматически удаляет его из formData
      // Можно скрыть поле или оставить только для чтения
      final isProcessName = fieldName == 'processName';

      // Маппим requestDate -> paymentDueDate (бэкенд еще может отправлять старое название)
      final actualFieldName =
          fieldName == 'requestDate' ? 'paymentDueDate' : fieldName;

      final fieldType = fieldSchema['type'] as String? ?? 'string';
      final fieldTitle = fieldSchema['title'] as String? ?? fieldName;
      final fieldFormat = fieldSchema['format'] as String?;
      // В режиме редактирования не требуем обязательные поля
      final isRequired =
          widget.isEditMode ? false : requiredFields.contains(fieldName);
      final defaultValue = fieldSchema['default'];
      // Проверяем оба варианта имени для initialValue
      final initialValue =
          widget.initialValues?[actualFieldName] ??
          widget.initialValues?[fieldName] ??
          defaultValue;
      final readOnly =
          fieldSchema['readOnly'] == true ||
          isProcessName; // processName всегда только для чтения
      final description = fieldSchema['description'] as String?;
      final minLength = fieldSchema['minLength'] as int?;
      final maxLength = fieldSchema['maxLength'] as int?;
      final minimum = fieldSchema['minimum'] as num?;
      final maximum = fieldSchema['maximum'] as num?;
      final enumValuesValue = fieldSchema['enum'];
      final List<dynamic>? enumValues =
          enumValuesValue is List ? enumValuesValue : null;
      final enumNamesValue = fieldSchema['enumNames'];
      final List<dynamic>? enumNames =
          enumNamesValue is List ? enumNamesValue : null;
      final options = fieldSchema['options'] as String?;

      Widget field;

      switch (fieldType) {
        case 'string':
        case 'text':
          if (fieldFormat == 'textarea' || fieldFormat == 'text') {
            field = FormBuilderTextField(
              name: actualFieldName,
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
              // Проверяем, что контекст еще валиден перед использованием
              if (!context.mounted) {
                field = const SizedBox.shrink();
                break;
              }
              final theme = context.appTheme;
              // Проверяем, что initialValue присутствует в списке опций
              final initialValueStr = initialValue?.toString();
              final validInitialValue =
                  initialValueStr != null &&
                          enumValues.any((v) => v.toString() == initialValueStr)
                      ? initialValueStr
                      : null;
              field = FormBuilderDropdown<String>(
                name: actualFieldName,
                initialValue: validInitialValue,
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
                    final name =
                        enumNames != null && index < enumNames.length
                            ? enumNames[index].toString()
                            : value;
                    return Text(name);
                  }).toList();
                },
                items:
                    enumValues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final value = entry.value.toString();
                      final name =
                          enumNames != null && index < enumNames.length
                              ? enumNames[index].toString()
                              : value;
                      return createStyledDropdownItem<String>(
                        context: context,
                        value: value,
                        child: Text(name),
                      );
                    }).toList(),
                validator:
                    isRequired
                        ? FormBuilderValidators.required(
                          errorText: 'Поле "$fieldTitle" обязательно',
                        )
                        : null,
              );
            } else if (options != null) {
              // Динамический список (departments, projects и т.д.)
              // TODO: Загрузить опции через API
              // Для динамических списков initialValue может быть не в списке опций
              // Устанавливаем null, чтобы избежать ошибки
              field = FormBuilderDropdown<String>(
                name: actualFieldName,
                initialValue: null,
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
                validator:
                    isRequired
                        ? FormBuilderValidators.required(
                          errorText: 'Поле "$fieldTitle" обязательно',
                        )
                        : null,
              );
            } else {
              // Обычное текстовое поле
              field = FormBuilderTextField(
                name: actualFieldName,
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
              name: actualFieldName,
              initialValue: dateValue,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                helperText: description,
              ),
              inputType: InputType.date,
              validator:
                  isRequired
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
              name: actualFieldName,
              initialValue: dateValue,
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.event),
                helperText: description,
              ),
              inputType: InputType.both,
              validator:
                  isRequired
                      ? FormBuilderValidators.required(
                        errorText: 'Поле "$fieldTitle" обязательно',
                      )
                      : null,
            );
          } else if (fieldFormat == 'file') {
            // TODO: Реализовать загрузку файлов
            field = FormBuilderTextField(
              name: actualFieldName,
              initialValue: initialValue?.toString(),
              enabled: !readOnly,
              decoration: InputDecoration(
                labelText: isRequired ? '$fieldTitle *' : fieldTitle,
                border: const OutlineInputBorder(),
                helperText: description ?? 'Загрузка файлов будет реализована',
              ),
              validator:
                  isRequired
                      ? FormBuilderValidators.required(
                        errorText: 'Поле "$fieldTitle" обязательно',
                      )
                      : null,
            );
          } else {
            // Обычное текстовое поле
            field = FormBuilderTextField(
              name: actualFieldName,
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
            name: actualFieldName,
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
              FormBuilderValidators.numeric(errorText: 'Введите число'),
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
            name: actualFieldName,
            initialValue: initialValue?.toString(),
            enabled: !readOnly,
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
              helperText: description ?? 'Введите значения через запятую',
            ),
            maxLines: 3,
            validator:
                isRequired
                    ? FormBuilderValidators.required(
                      errorText: 'Поле "$fieldTitle" обязательно',
                    )
                    : null,
          );
          break;

        default:
          field = FormBuilderTextField(
            name: actualFieldName,
            initialValue: initialValue?.toString(),
            enabled: !readOnly,
            decoration: InputDecoration(
              labelText: isRequired ? '$fieldTitle *' : fieldTitle,
              border: const OutlineInputBorder(),
              helperText: description,
            ),
            validator:
                isRequired
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
  final OnFieldChanged? onFieldChanged;
  final Map<String, dynamic> localFieldValues;
  final bool isEditMode;

  const UniversalBlock({
    super.key,
    required this.blockName,
    required this.label,
    required this.elements,
    this.formKey,
    this.initialValues,
    this.onFieldChanged,
    required this.localFieldValues,
    this.isEditMode = false,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Элементы блока
        ...elements.asMap().entries.map((entry) {
          final index = entry.key;
          final element = entry.value as Map<String, dynamic>;
          final isLast = index == elements.length - 1;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElementFormSwitcher(
                key: ValueKey('$blockName-${element['name']}-$index'),
                element: element,
                blockName: blockName,
                formKey: formKey,
                initialValues: initialValues,
                onFieldChanged: onFieldChanged,
                localFieldValues: localFieldValues,
                isEditMode: isEditMode,
              ),
              if (!isLast) const SizedBox(height: 16),
            ],
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
  final OnFieldChanged? onFieldChanged;
  final Map<String, dynamic> localFieldValues;
  final bool isEditMode;

  const ElementFormSwitcher({
    super.key,
    required this.element,
    required this.blockName,
    this.formKey,
    this.initialValues,
    this.onFieldChanged,
    required this.localFieldValues,
    this.isEditMode = false,
  });

  @override
  State<ElementFormSwitcher> createState() => _ElementFormSwitcherState();
}

class _ElementFormSwitcherState extends State<ElementFormSwitcher> {
  String get _fieldName {
    final elementName = widget.element['name'] as String? ?? '';
    // Маппим requestDate -> paymentDueDate (бэкенд еще может отправлять старое название)
    final actualElementName =
        elementName == 'requestDate' ? 'paymentDueDate' : elementName;
    return '${widget.blockName}.$actualElementName';
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем видимость элемента
    final isVisible = _checkVisibility(context);
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final elementType = widget.element['type'] as String? ?? 'text';
    final label = widget.element['label'] as String? ?? widget.element['name'];
    // В режиме редактирования не требуем обязательные поля
    final isRequired =
        widget.isEditMode ? false : (widget.element['require'] == true);
    final defaultValue = widget.element['defaultValue'];
    final initialValue = _getInitialValue();

    return _buildFieldByType(
      elementType,
      label,
      isRequired,
      defaultValue,
      initialValue,
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
        final optionsValue = widget.element['options'];
        final List<dynamic>? options =
            optionsValue is List
                ? optionsValue
                : null; // Если options не список, не используем его
        return _buildSelectField(
          label: label,
          isRequired: isRequired,
          initialValue: initialValue ?? defaultValue,
          options: options,
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

  /// Проверяет видимость элемента на основе условий из props.visible и props.hiddenByRole
  bool _checkVisibility(BuildContext context) {
    final props = widget.element['props'] as Map<String, dynamic>?;
    if (props == null) return true;

    // Если поле скрыто по роли, скрываем его независимо от других условий
    final hiddenByRole = props['hiddenByRole'] == true;
    if (hiddenByRole) return false;

    final visible = props['visible'] as Map<String, dynamic>?;
    if (visible == null) return true;

    // Проверяем все условия видимости
    for (var entry in visible.entries) {
      final fieldPath = entry.key; // например "category" или "periodicity"
      final expectedValue = entry.value; // например "LABOR_FUND" или "CONSTANT"

      // Ищем значение в localFieldValues (приоритет) и в FormBuilder
      dynamic actualValue;

      // Сначала проверяем локальное хранилище (самые актуальные данные)
      final fullFieldPath = '${widget.blockName}.$fieldPath';
      if (widget.localFieldValues.containsKey(fullFieldPath)) {
        actualValue = widget.localFieldValues[fullFieldPath];
      } else {
        // Если нет в локальном хранилище, пробуем FormBuilder
        FormBuilderState? formState;
        if (widget.formKey?.currentState != null) {
          formState = widget.formKey!.currentState;
        } else {
          try {
            // Проверяем, что контекст еще валиден
            if (mounted && context.mounted) {
              formState = FormBuilder.of(context);
            }
          } catch (e) {
            // FormBuilder не найден в контексте или контекст невалиден
            formState = null;
          }
        }

        if (formState != null) {
          final formValues = formState.value;
          final flattenedValues = _flattenMap(formValues);
          actualValue = _getFieldValue(flattenedValues, fieldPath);
        }
      }

      // Сравниваем значения как строки для надежности
      final expectedStr = expectedValue?.toString();
      final actualStr = actualValue?.toString();

      if (actualStr != expectedStr) {
        return false;
      }
    }

    return true;
  }

  /// Получает значение поля из плоского объекта
  dynamic _getFieldValue(
    Map<String, dynamic> flattenedValues,
    String fieldPath,
  ) {
    // Сначала ищем поле в том же блоке (с префиксом блока)
    final blockPrefix = widget.blockName;
    final fullFieldPath = '$blockPrefix.$fieldPath';
    var value = flattenedValues[fullFieldPath];
    if (value != null) return value;

    // Ищем без префикса (для совместимости со старым форматом)
    value = flattenedValues[fieldPath];
    if (value != null) return value;

    // Поддержка путей вида "blocks_new.CheckIn.status"
    final normalizedPath = fieldPath.replaceAll('[', '.').replaceAll(']', '');
    return flattenedValues[normalizedPath];
  }

  /// Преобразует вложенный объект в плоский
  Map<String, dynamic> _flattenMap(
    Map<String, dynamic> map, {
    String prefix = '',
  }) {
    final result = <String, dynamic>{};
    for (var entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is Map) {
        result.addAll(_flattenMap(value as Map<String, dynamic>, prefix: key));
      } else if (value is List) {
        // Обработка массивов (например, для deviceCheckPhoto.0.value)
        final list = value;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            result.addAll(
              _flattenMap(list[i] as Map<String, dynamic>, prefix: '$key.$i'),
            );
          } else {
            result['$key.$i'] = list[i];
          }
        }
      } else {
        // Если значение не Map и не List, просто сохраняем его
        result[key] = value;
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
  List<dynamic> _filterOptions(
    BuildContext context,
    List<dynamic>? options,
    String? parent,
  ) {
    if (options == null || parent == null) return options ?? [];

    FormBuilderState? formState;
    if (widget.formKey?.currentState != null) {
      formState = widget.formKey!.currentState;
    } else {
      try {
        // Проверяем, что контекст еще валиден
        if (mounted && context.mounted) {
          formState = FormBuilder.of(context);
        }
      } catch (e) {
        // FormBuilder не найден или контекст невалиден
        return options;
      }
    }

    if (formState == null) return options;

    final formValues = formState.value;
    final flattenedValues = _flattenMap(formValues);

    // Получаем значение родительского поля
    final parentFieldName = '${widget.blockName}.$parent';
    final parentValue =
        flattenedValues[parentFieldName] ?? flattenedValues[parent];

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
      validator:
          isRequired
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
        onFieldChanged: widget.onFieldChanged,
      );
    }

    // Если нет родительского поля, используем обычный FormBuilderDropdown
    // Проверяем, что контекст еще валиден перед использованием
    if (!context.mounted) {
      return const SizedBox.shrink();
    }
    final theme = context.appTheme;
    // Проверяем, что initialValue присутствует в списке опций
    final initialValueStr = initialValue?.toString();
    String? validInitialValue;
    if (initialValueStr != null && options != null && options.isNotEmpty) {
      // Проверяем наличие значения в опциях
      final hasValue = options.any((option) {
        if (option is Map<String, dynamic>) {
          return option['value']?.toString() == initialValueStr;
        } else {
          return option.toString() == initialValueStr;
        }
      });
      validInitialValue = hasValue ? initialValueStr : null;
    } else {
      validInitialValue = null;
    }
    return FormBuilderDropdown<String>(
      name: _fieldName,
      initialValue: validInitialValue,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      dropdownColor: theme.backgroundSurface,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      selectedItemBuilder: (BuildContext context) {
        return (options ?? []).map<Widget>((option) {
          if (option is Map<String, dynamic>) {
            final name = option['name']?.toString();
            final value = option['value']?.toString();
            final displayText = name ?? value ?? '';
            return Text(displayText);
          } else {
            return Text(option.toString());
          }
        }).toList();
      },
      items:
          (options ?? []).isEmpty
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
                  final name = option['name']?.toString();
                  if (value == null) {
                    return const DropdownMenuItem<String>(
                      value: null,
                      enabled: false,
                      child: Text('Нет доступных опций'),
                    );
                  }
                  final displayText = name ?? value;
                  return createStyledDropdownItem<String>(
                    context: context,
                    value: value,
                    child: Text(displayText),
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
        // Проверяем mounted перед вызовом callback
        if (!mounted) return;
        // Уведомляем родителя об изменении для перестройки формы
        widget.onFieldChanged?.call(_fieldName, value);
      },
      validator:
          isRequired
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
        FormBuilderValidators.numeric(errorText: 'Введите число'),
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
      validator:
          isRequired
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
      onChanged: (value) {
        // Проверяем mounted перед вызовом callback
        if (!mounted) return;
        // Уведомляем родителя об изменении для реактивности
        widget.onFieldChanged?.call(_fieldName, value);
      },
      validator:
          isRequired
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
  final List<dynamic> Function(BuildContext, List<dynamic>?, String?)
  filterOptions;
  final OnFieldChanged? onFieldChanged;

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
    this.onFieldChanged,
  });

  @override
  State<_ReactiveSelectField> createState() => _ReactiveSelectFieldState();
}

class _ReactiveSelectFieldState extends State<_ReactiveSelectField> {
  bool _isDisposed = false;
  String? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  // Получаем значение родительского поля
  String? _getParentValue() {
    if (_isDisposed || !mounted) return null;

    FormBuilderState? formState;
    if (widget.formKey?.currentState != null) {
      formState = widget.formKey!.currentState;
    } else {
      try {
        if (mounted && context.mounted) {
          formState = FormBuilder.of(context);
        }
      } catch (e) {
        formState = null;
      }
    }

    if (formState == null) return null;

    final formValues = formState.value;
    final flattenedValues = _flattenMap(formValues);
    return flattenedValues[widget.parentFieldName]?.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, что виджет еще mounted
    if (_isDisposed || !mounted || !context.mounted) {
      return const SizedBox.shrink();
    }

    // Получаем значение родительского поля
    final parentValue = _getParentValue();

    // Фильтруем опции на основе значения родителя
    final currentOptions = widget.filterOptions(
      context,
      widget.options,
      widget.parent,
    );

    // Проверяем, что текущее значение присутствует в опциях
    String? validInitialValue;
    if (_currentValue != null && currentOptions.isNotEmpty) {
      final hasValue = currentOptions.any((option) {
        if (option is Map<String, dynamic>) {
          return option['value']?.toString() == _currentValue;
        } else {
          return option.toString() == _currentValue;
        }
      });
      validInitialValue = hasValue ? _currentValue : null;
    }

    final theme = context.appTheme;
    return FormBuilderDropdown<String>(
      key: ValueKey('${widget.fieldName}-$parentValue'),
      name: widget.fieldName,
      initialValue: validInitialValue,
      decoration: InputDecoration(
        labelText: widget.isRequired ? '${widget.label} *' : widget.label,
        border: const OutlineInputBorder(),
      ),
      dropdownColor: theme.backgroundSurface,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      selectedItemBuilder: (BuildContext context) {
        return currentOptions.map<Widget>((option) {
          if (option is Map<String, dynamic>) {
            return Text(
              option['name']?.toString() ?? option['value']?.toString() ?? '',
            );
          } else {
            return Text(option.toString());
          }
        }).toList();
      },
      items:
          currentOptions.isEmpty
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
        // Проверяем disposed перед любыми действиями
        if (_isDisposed || !mounted) return;

        _currentValue = value;

        // Уведомляем родителя об изменении для перестройки формы
        if (!_isDisposed && mounted) {
          widget.onFieldChanged?.call(widget.fieldName, value);
        }
      },
      validator:
          widget.isRequired
              ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Поле "${widget.label}" обязательно';
                }
                return null;
              }
              : null,
    );
  }

  Map<String, dynamic> _flattenMap(
    Map<String, dynamic> map, {
    String prefix = '',
  }) {
    final result = <String, dynamic>{};
    for (var entry in map.entries) {
      final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is Map) {
        result.addAll(_flattenMap(value as Map<String, dynamic>, prefix: key));
      } else if (value is List) {
        final list = value;
        for (var i = 0; i < list.length; i++) {
          if (list[i] is Map) {
            result.addAll(
              _flattenMap(list[i] as Map<String, dynamic>, prefix: '$key.$i'),
            );
          } else {
            result['$key.$i'] = list[i];
          }
        }
      } else {
        // Если значение не Map и не List, просто сохраняем его
        result[key] = value;
      }
    }
    return result;
  }
}
