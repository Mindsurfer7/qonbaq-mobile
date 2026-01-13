import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/models/validation_error.dart';
import '../../data/models/task_model.dart';
import '../../core/services/voice_context.dart';
import '../providers/auth_provider.dart';
import 'user_selector_widget.dart';
import 'voice_record_block.dart';

/// Форма создания задачи
class CreateTaskForm extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final Function(Task) onSubmit;
  final VoidCallback onCancel;
  final String? error; // Общая ошибка от сервера
  final List<ValidationError>? validationErrors; // Ошибки валидации по полям
  final Function(String)? onError; // Callback для обновления ошибки
  final String? initialDescription; // Начальное значение для поля описания
  final TaskModel?
  initialTaskData; // Предзаполненные данные задачи из voice-assist

  const CreateTaskForm({
    super.key,
    required this.businessId,
    required this.userRepository,
    required this.onSubmit,
    required this.onCancel,
    this.error,
    this.validationErrors,
    this.onError,
    this.initialDescription,
    this.initialTaskData,
  });

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  bool _isImportant = false;
  bool _isRecurring = false;
  bool _hasControlPoint = false;
  bool _dontForget = false;
  String? _assignedToId;
  String? _assignedById;
  // Храним ошибки валидации для отображения в полях
  final Map<String, String> _fieldErrors = {};

  @override
  void didUpdateWidget(CreateTaskForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Обновляем контроллер описания, если изменилось initialDescription
    if (widget.initialDescription != oldWidget.initialDescription) {
      _descriptionController.text = widget.initialDescription ?? '';
      _formKey.currentState?.fields['description']?.didChange(
        widget.initialDescription,
      );
    }

    // Применяем ошибки валидации к полям формы
    if (widget.validationErrors != null &&
        widget.validationErrors!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyValidationErrors();
      });
    } else if (widget.validationErrors == null ||
        widget.validationErrors!.isEmpty) {
      // Очищаем ошибки, если их нет
      setState(() {
        _fieldErrors.clear();
      });
    }
  }

  void _applyValidationErrors() {
    if (_formKey.currentState == null) return;

    final Map<String, String> newErrors = {};

    for (final error in widget.validationErrors ?? []) {
      // Маппинг полей из JSON в поля формы
      final fieldName = _mapFieldName(error.field);
      final field = _formKey.currentState?.fields[fieldName];

      if (field != null) {
        // Сохраняем ошибку для отображения
        newErrors[fieldName] = error.message;
        // Устанавливаем ошибку валидации для поля
        field.invalidate(error.message);
        // Вызываем validate, чтобы ошибка отобразилась
        field.validate();
      }
    }

    // Обновляем состояние для отображения ошибок
    setState(() {
      _fieldErrors.clear();
      _fieldErrors.addAll(newErrors);
    });
  }

  @override
  void initState() {
    super.initState();
    // Устанавливаем начальное значение для описания, если есть
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    // Применяем предзаполненные данные задачи, если есть
    if (widget.initialTaskData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialTaskData(widget.initialTaskData!);
      });
    } else {
      // Если нет предзаполненных данных, устанавливаем текущего пользователя как исполнителя
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setCurrentUserAsAssignee();
      });
    }
    // Применяем ошибки валидации после первой отрисовки, если они есть
    if (widget.validationErrors != null &&
        widget.validationErrors!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyValidationErrors();
      });
    }
  }

  /// Устанавливает текущего пользователя как исполнителя
  void _setCurrentUserAsAssignee() {
    if (!mounted || _formKey.currentState == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Устанавливаем текущего пользователя как исполнителя, если он не установлен
    if (currentUserId != null && _assignedToId == null) {
      setState(() {
        _assignedToId = currentUserId;
      });
      _formKey.currentState?.fields['assignedTo']?.didChange(currentUserId);
    }
  }

  /// Применяет предзаполненные данные задачи к форме
  void _applyInitialTaskData(TaskModel taskData) {
    if (_formKey.currentState == null) return;

    final formState = _formKey.currentState!;

    // Заполняем поля формы предзаполненными данными
    if (taskData.title.isNotEmpty) {
      formState.fields['title']?.didChange(taskData.title);
    }
    if (taskData.description != null && taskData.description!.isNotEmpty) {
      _descriptionController.text = taskData.description!;
      formState.fields['description']?.didChange(taskData.description);
    }
    formState.fields['status']?.didChange(taskData.status);
    if (taskData.assignedTo != null && taskData.assignedTo!.isNotEmpty) {
      _assignedToId = taskData.assignedTo;
      formState.fields['assignedTo']?.didChange(taskData.assignedTo);
    } else {
      // Если в предзаполненных данных нет исполнителя, устанавливаем текущего пользователя
      _setCurrentUserAsAssignee();
    }
    if (taskData.assignedBy != null && taskData.assignedBy!.isNotEmpty) {
      _assignedById = taskData.assignedBy;
      formState.fields['assignedBy']?.didChange(taskData.assignedBy);
    }
    // assignmentDate не обрабатываем, так как оно всегда устанавливается автоматически
    if (taskData.deadline != null) {
      formState.fields['deadline']?.didChange(taskData.deadline);
    }
    if (taskData.isImportant) {
      setState(() {
        _isImportant = true;
      });
      formState.fields['isImportant']?.didChange(true);
    }
    if (taskData.isRecurring) {
      setState(() {
        _isRecurring = true;
      });
      formState.fields['isRecurring']?.didChange(true);
    }
    if (taskData.hasControlPoint) {
      setState(() {
        _hasControlPoint = true;
      });
      formState.fields['hasControlPoint']?.didChange(true);
    }
    if (taskData.dontForget) {
      setState(() {
        _dontForget = true;
      });
      formState.fields['dontForget']?.didChange(true);
    }

    setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  /// Маппинг имен полей из JSON ответа в имена полей формы
  String _mapFieldName(String jsonField) {
    // Прямое соответствие
    final directMapping = {
      'title': 'title',
      'description': 'description',
      'status': 'status',
      'assignedTo': 'assignedTo',
      'assignedBy': 'assignedBy',
      'assignmentDate': 'assignmentDate',
      'deadline': 'deadline',
      'isImportant': 'isImportant',
      'isRecurring': 'isRecurring',
      'hasControlPoint': 'hasControlPoint',
      'dontForget': 'dontForget',
      'businessId':
          'businessId', // Хотя этого поля нет в форме, но может быть ошибка
    };

    // Если поле вложенное (например, recurrence.frequency)
    if (jsonField.contains('.')) {
      final parts = jsonField.split('.');
      // Для вложенных полей пока просто берем первое поле
      // Можно расширить логику при необходимости
      return directMapping[parts[0]] ?? jsonField;
    }

    return directMapping[jsonField] ?? jsonField;
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Показываем ошибку от сервера, если есть
            if (widget.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            // Блок голосовой записи
            VoiceRecordBlock(
              context: VoiceContext.task,
              onResultReceived: (result) {
                // Результат - TaskModel для контекста task
                final taskData = result as TaskModel;
                // Применяем предзаполненные данные к форме
                _applyInitialTaskData(taskData);
              },
              onError: (error) {
                if (widget.onError != null) {
                  widget.onError!(error);
                }
              },
            ),
            const SizedBox(height: 16),
            // Заголовок
            FormBuilderTextField(
              name: 'title',
              focusNode: _titleFocusNode,
              decoration: InputDecoration(
                labelText: 'Название задачи *',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['title'],
                errorMaxLines: 2,
              ),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                _descriptionFocusNode.requestFocus();
              },
              validator: FormBuilderValidators.required(
                errorText: 'Название задачи обязательно',
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            FormBuilderTextField(
              name: 'description',
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              decoration: InputDecoration(
                labelText: 'Описание',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['description'],
                errorMaxLines: 2,
              ),
              maxLines: 4,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 16),

            // Статус
            FormBuilderDropdown<TaskStatus>(
              name: 'status',
              decoration: InputDecoration(
                labelText: 'Статус',
                border: const OutlineInputBorder(),
                errorText: _fieldErrors['status'],
                errorMaxLines: 2,
              ),
              initialValue: TaskStatus.inProgress,
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(
                context.appTheme.borderRadius,
              ),
              selectedItemBuilder: (BuildContext context) {
                return TaskStatus.values.map<Widget>((TaskStatus status) {
                  return Text(_getStatusText(status));
                }).toList();
              },
              items:
                  TaskStatus.values
                      .map(
                        (status) => createStyledDropdownItem<TaskStatus>(
                          context: context,
                          value: status,
                          child: Text(_getStatusText(status)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Исполнитель
            UserSelectorWidget(
              businessId: widget.businessId,
              userRepository: widget.userRepository,
              selectedUserId: _assignedToId,
              onUserSelected: (userId) {
                setState(() {
                  _assignedToId = userId;
                });
                _formKey.currentState?.fields['assignedTo']?.didChange(userId);
              },
              label: 'Исполнитель',
            ),
            const SizedBox(height: 16),

            // Поручитель
            UserSelectorWidget(
              businessId: widget.businessId,
              userRepository: widget.userRepository,
              selectedUserId: _assignedById,
              onUserSelected: (userId) {
                setState(() {
                  _assignedById = userId;
                });
                _formKey.currentState?.fields['assignedBy']?.didChange(userId);
              },
              label: 'Поручитель',
            ),
            const SizedBox(height: 16),

            // Дата поручения (readonly, автоматически устанавливается при создании)
            TextFormField(
              initialValue: _formatDateTime(DateTime.now()),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Дата поручения',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),

            // Дедлайн
            FormBuilderDateTimePicker(
              name: 'deadline',
              decoration: InputDecoration(
                labelText: 'Дедлайн',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.event),
                errorText: _fieldErrors['deadline'],
                errorMaxLines: 2,
              ),
              inputType: InputType.both,
            ),
            const SizedBox(height: 16),

            // Важная задача
            FormBuilderCheckbox(
              name: 'isImportant',
              title: const Text('Важная задача'),
              initialValue: _isImportant,
              onChanged: (value) {
                setState(() {
                  _isImportant = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),

            // Регулярная задача
            FormBuilderCheckbox(
              name: 'isRecurring',
              title: const Text('Регулярная задача'),
              initialValue: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),

            // Задача с точкой контроля
            FormBuilderCheckbox(
              name: 'hasControlPoint',
              title: const Text('Задача с точкой контроля'),
              initialValue: _hasControlPoint,
              onChanged: (value) {
                setState(() {
                  _hasControlPoint = value ?? false;
                });
              },
            ),
            const SizedBox(height: 8),

            // Не забыть выполнить
            FormBuilderCheckbox(
              name: 'dontForget',
              title: const Text('Заметки на ходу'),
              initialValue: _dontForget,
              onChanged: (value) {
                setState(() {
                  _dontForget = value ?? false;
                });
              },
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
                  child: const Text('Создать'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    // Очищаем ошибки валидации перед новой отправкой
    setState(() {
      _fieldErrors.clear();
    });

    // Сохраняем значения из UserSelectorWidget
    _formKey.currentState?.fields['assignedTo']?.didChange(_assignedToId);
    _formKey.currentState?.fields['assignedBy']?.didChange(_assignedById);

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      // Создаем задачу
      final task = Task(
        id: '', // Будет присвоен на сервере
        businessId: widget.businessId,
        title: formData['title'] as String,
        description: formData['description'] as String?,
        status: formData['status'] as TaskStatus? ?? TaskStatus.inProgress,
        assignedTo: _assignedToId,
        assignedBy: _assignedById,
        assignmentDate:
            DateTime.now(), // Всегда текущая дата/время при создании
        deadline: formData['deadline'] as DateTime?,
        isImportant: formData['isImportant'] as bool? ?? false,
        isRecurring: formData['isRecurring'] as bool? ?? false,
        hasControlPoint: formData['hasControlPoint'] as bool? ?? false,
        dontForget: formData['dontForget'] as bool? ?? false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSubmit(task);
    } else {
      // Прокручиваем к началу формы, чтобы пользователь увидел ошибки валидации
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Ожидает';
      case TaskStatus.inProgress:
        return 'В работе';
      case TaskStatus.completed:
        return 'Завершена';
      case TaskStatus.cancelled:
        return 'Отменена';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
