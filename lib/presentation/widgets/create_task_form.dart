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
import '../providers/profile_provider.dart';
import 'user_selector_widget.dart';
import 'voice_record_block.dart';

/// Форма создания задачи
class CreateTaskForm extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final Function(TaskModel) onSubmit;
  final VoidCallback onCancel;
  final String? error; // Общая ошибка от сервера
  final List<ValidationError>? validationErrors; // Ошибки валидации по полям
  final Function(String)? onError; // Callback для обновления ошибки
  final String? initialDescription; // Начальное значение для поля описания
  final TaskModel?
      initialTaskData; // Предзаполненные данные задачи из voice-assist
  final String? customerId; // ID клиента для привязки задачи
  final String? customerName; // Название клиента для отображения

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
    this.customerId,
    this.customerName,
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
  bool _isControlPoint = false; // Переименовано из hasControlPoint для соответствия API
  bool _isMeAssignee = false; // Checkbox "Я исполнитель в задаче"
  // bool _dontForget = false;
  String? _assignedToId;
  String? _assignedById;
  // Параметры регулярности
  RecurrenceFrequency? _recurrenceFrequency;
  int _recurrenceInterval = 1; // Интервал (каждые N дней/недель/месяцев)
  String? _timeOfDay; // Время создания задачи в формате "HH:MM"
  List<int>? _daysOfWeek; // Дни недели для WEEKLY (0-6, где 0=воскресенье)
  int? _recurrenceDayOfMonth; // Для monthly: день месяца (1-31)
  DateTime? _startDate; // Дата начала создания задач
  DateTime? _endDate; // Дата окончания создания задач (null = бесконечно)
  int? _deadlineOffset; // Смещение дедлайна в часах
  // Метрики для точек контроля
  final List<_ControlPointMetric> _metrics = [];
  // Храним ошибки валидации для отображения в полях
  final Map<String, String> _fieldErrors = {};
  String? _currentUserFullName; // Полное имя текущего пользователя для отображения

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
    // Загружаем имя текущего пользователя и устанавливаем его как инициатора
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentUserName();
      _setCurrentUserAsInitiator();
    });
    // Применяем предзаполненные данные задачи, если есть
    if (widget.initialTaskData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialTaskData(widget.initialTaskData!);
      });
    }
    // Больше не устанавливаем исполнителя автоматически - пользователь должен выбрать через checkbox
    // Применяем ошибки валидации после первой отрисовки, если они есть
    if (widget.validationErrors != null &&
        widget.validationErrors!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyValidationErrors();
      });
    }
  }

  /// Загружает имя текущего пользователя из списка сотрудников
  Future<void> _loadCurrentUserName() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    if (currentUserId == null) return;

    // Получаем список сотрудников из кэша
    var employees = profileProvider.getEmployeesForBusiness(widget.businessId);
    
    // Если сотрудников нет в кэше, загружаем их
    if (employees == null || employees.isEmpty) {
      await profileProvider.loadEmployees(widget.businessId);
      employees = profileProvider.getEmployeesForBusiness(widget.businessId);
    }

    if (employees != null && employees.isNotEmpty) {
      try {
        final currentEmployee = employees.firstWhere(
          (e) => e.id == currentUserId,
        );
        if (mounted) {
          setState(() {
            _currentUserFullName = currentEmployee.fullName;
          });
        }
      } catch (e) {
        // Пользователь не найден в списке сотрудников
        if (mounted) {
          setState(() {
            _currentUserFullName = null;
          });
        }
      }
    }
  }

  /// Устанавливает текущего пользователя как исполнителя
  void _setCurrentUserAsAssignee() {
    if (!mounted || _formKey.currentState == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Устанавливаем текущего пользователя как исполнителя
    if (currentUserId != null) {
      setState(() {
        _assignedToId = currentUserId;
      });
      _formKey.currentState?.fields['assignedTo']?.didChange(currentUserId);
    }
  }

  /// Очищает поле исполнителя
  void _clearAssignee() {
    if (!mounted || _formKey.currentState == null) return;

    setState(() {
      _assignedToId = null;
    });
    _formKey.currentState?.fields['assignedTo']?.didChange(null);
  }

  /// Обработчик изменения checkbox "Я исполнитель"
  void _onMeAssigneeChanged(bool? value) {
    setState(() {
      _isMeAssignee = value ?? false;
    });

    if (_isMeAssignee) {
      // Если checkbox включен, устанавливаем текущего пользователя как исполнителя
      _setCurrentUserAsAssignee();
    } else {
      // Если checkbox выключен, очищаем поле исполнителя
      _clearAssignee();
    }
  }

  /// Устанавливает текущего пользователя как инициатора
  void _setCurrentUserAsInitiator() {
    if (!mounted || _formKey.currentState == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Всегда устанавливаем текущего пользователя как инициатора
    if (currentUserId != null) {
      setState(() {
        _assignedById = currentUserId;
      });
      _formKey.currentState?.fields['assignedBy']?.didChange(currentUserId);
    }
  }

  /// Проверяет, может ли пользователь изменять исполнителя задачи (назначать на других)
  bool _canChangeAssignee() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Админы, гендиректоры, руководители проектов и отделов могут изменять исполнителя
    return currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true ||
        profile?.orgStructure.isProjectManager == true ||
        profile?.orgStructure.isDepartmentHead == true;
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
    
    // Если пользователь может изменять исполнителя и в предзаполненных данных есть исполнитель, используем его
    if (_canChangeAssignee() && taskData.assignedTo != null && taskData.assignedTo!.isNotEmpty) {
      _assignedToId = taskData.assignedTo;
      formState.fields['assignedTo']?.didChange(taskData.assignedTo);
      // Проверяем, является ли исполнитель текущим пользователем
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;
      if (currentUserId != null && taskData.assignedTo == currentUserId) {
        setState(() {
          _isMeAssignee = true;
        });
      }
    }
    // Больше не устанавливаем исполнителя автоматически
    // Инициатор всегда устанавливается автоматически как текущий пользователь
    _setCurrentUserAsInitiator();
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
        _isControlPoint = true;
      });
      formState.fields['isControlPoint']?.didChange(true);
    }
    // Обработка регулярности
    if (taskData.isRecurring && taskData.recurrence != null) {
      setState(() {
        _isRecurring = true;
        _recurrenceFrequency = taskData.recurrence!.frequency;
        _recurrenceDayOfMonth = taskData.recurrence!.dayOfMonth;
      });
      formState.fields['isRecurring']?.didChange(true);
      formState.fields['recurrenceFrequency']?.didChange(taskData.recurrence!.frequency);
      if (taskData.recurrence!.dayOfMonth != null) {
        formState.fields['recurrenceDayOfMonth']?.didChange(taskData.recurrence!.dayOfMonth);
      }
    }
    // if (taskData.dontForget) {
    //   setState(() {
    //     _dontForget = true;
    //   });
    //   formState.fields['dontForget']?.didChange(true);
    // }

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
            // Поле клиента (если указан)
            if (widget.customerId != null && widget.customerName != null) ...[
              FormBuilderTextField(
                name: 'customer',
                initialValue: widget.customerName,
                decoration: InputDecoration(
                  labelText: 'Клиент',
                  icon: const Icon(Icons.business),
                  suffixIcon: const Icon(Icons.lock, size: 16),
                  helperText: 'Задача будет привязана к этому клиенту',
                ),
                readOnly: true,
                enabled: false,
              ),
              const SizedBox(height: 16),
            ],
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
                return TaskStatus.values
                    .where((status) => status != TaskStatus.pending)
                    .map<Widget>((TaskStatus status) {
                  return Text(_getStatusText(status));
                }).toList();
              },
              items:
                  TaskStatus.values
                      .where((status) => status != TaskStatus.pending)
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

            // Checkbox "Я исполнитель в задаче"
            FormBuilderCheckbox(
              name: 'isMeAssignee',
              title: const Text('Я исполнитель в задаче'),
              initialValue: _isMeAssignee,
              onChanged: _onMeAssigneeChanged,
            ),
            const SizedBox(height: 8),

            // Исполнитель
            _canChangeAssignee()
                ? UserSelectorWidget(
                    businessId: widget.businessId,
                    userRepository: widget.userRepository,
                    selectedUserId: _assignedToId,
                    onUserSelected: (userId) {
                      setState(() {
                        _assignedToId = userId;
                        // Обновляем checkbox в зависимости от выбранного пользователя
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final currentUserId = authProvider.user?.id;
                        _isMeAssignee = (currentUserId != null && userId == currentUserId);
                      });
                      _formKey.currentState?.fields['assignedTo']?.didChange(userId);
                    },
                    label: 'Исполнитель',
                  )
                : TextFormField(
                    initialValue: _assignedToId != null 
                        ? (_currentUserFullName ?? 'Загрузка...')
                        : '',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Исполнитель',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.person),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      helperText: _assignedToId != null 
                          ? 'Задача будет назначена на вас'
                          : 'Выберите "Я исполнитель в задаче" для назначения на себя',
                    ),
                  ),
            const SizedBox(height: 16),

            // Крайний срок
            FormBuilderDateTimePicker(
              name: 'deadline',
              decoration: InputDecoration(
                labelText: 'Крайний срок',
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
                  final newValue = value ?? false;
                  if (newValue && _isControlPoint) {
                    // Если включаем регулярную задачу, выключаем точку контроля
                    _isControlPoint = false;
                    _metrics.clear();
                    _formKey.currentState?.fields['isControlPoint']?.didChange(false);
                  }
                  _isRecurring = newValue;
                  // Очищаем параметры регулярности при выключении
                  if (!_isRecurring) {
                    _recurrenceFrequency = null;
                    _recurrenceInterval = 1;
                    _timeOfDay = null;
                    _daysOfWeek = null;
                    _recurrenceDayOfMonth = null;
                    _startDate = null;
                    _endDate = null;
                    _deadlineOffset = null;
                    _formKey.currentState?.fields['recurrenceFrequency']?.didChange(null);
                    _formKey.currentState?.fields['recurrenceInterval']?.didChange(null);
                    _formKey.currentState?.fields['timeOfDay']?.didChange(null);
                    _formKey.currentState?.fields['daysOfWeek']?.didChange(null);
                    _formKey.currentState?.fields['recurrenceDayOfMonth']?.didChange(null);
                    _formKey.currentState?.fields['startDate']?.didChange(null);
                    _formKey.currentState?.fields['endDate']?.didChange(null);
                    _formKey.currentState?.fields['deadlineOffset']?.didChange(null);
                  }
                });
              },
            ),
            // Поля для настройки регулярности (показываются только если задача регулярная, НО НЕ точка контроля)
            if (_isRecurring && !_isControlPoint) ...[
              const SizedBox(height: 16),
              // Тип регулярности
              FormBuilderDropdown<RecurrenceFrequency>(
                name: 'recurrenceFrequency',
                decoration: InputDecoration(
                  labelText: 'Тип регулярности *',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['recurrenceFrequency'],
                  errorMaxLines: 2,
                ),
                initialValue: _recurrenceFrequency,
                dropdownColor: context.appTheme.backgroundSurface,
                borderRadius: BorderRadius.circular(
                  context.appTheme.borderRadius,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return RecurrenceFrequency.values
                      .map<Widget>((RecurrenceFrequency frequency) {
                    return Text(_getRecurrenceFrequencyText(frequency));
                  }).toList();
                },
                items: RecurrenceFrequency.values
                    .map(
                      (frequency) => createStyledDropdownItem<RecurrenceFrequency>(
                        context: context,
                        value: frequency,
                        child: Text(_getRecurrenceFrequencyText(frequency)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _recurrenceFrequency = value;
                    // Очищаем специфичные поля при смене типа регулярности
                    if (value != RecurrenceFrequency.monthly) {
                      _recurrenceDayOfMonth = null;
                      _formKey.currentState?.fields['recurrenceDayOfMonth']?.didChange(null);
                    }
                    if (value != RecurrenceFrequency.weekly) {
                      _daysOfWeek = null;
                      _formKey.currentState?.fields['daysOfWeek']?.didChange(null);
                    }
                  });
                },
                validator: FormBuilderValidators.required(
                  errorText: 'Выберите тип регулярности',
                ),
              ),
              const SizedBox(height: 16),
              // Интервал
              FormBuilderTextField(
                name: 'recurrenceInterval',
                initialValue: _recurrenceInterval.toString(),
                decoration: InputDecoration(
                  labelText: 'Интервал',
                  helperText: 'Каждые N дней/недель/месяцев (по умолчанию 1)',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['recurrenceInterval'],
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    final interval = int.tryParse(value);
                    if (interval != null && interval > 0) {
                      setState(() {
                        _recurrenceInterval = interval;
                      });
                    }
                  }
                },
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.min(1, errorText: 'Интервал должен быть больше 0'),
                ]),
              ),
              const SizedBox(height: 16),
              // Время создания задачи
              FormBuilderTextField(
                name: 'timeOfDay',
                initialValue: _timeOfDay,
                decoration: InputDecoration(
                  labelText: 'Время создания задачи',
                  helperText: 'Формат: HH:MM (например, 09:00)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                  errorText: _fieldErrors['timeOfDay'],
                  errorMaxLines: 2,
                ),
                onChanged: (value) {
                  setState(() {
                    _timeOfDay = value;
                  });
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                    if (!timeRegex.hasMatch(value)) {
                      return 'Неверный формат времени. Используйте HH:MM';
                    }
                  }
                  return null;
                },
              ),
              // Поле для выбора дня месяца (только для monthly)
              if (_recurrenceFrequency == RecurrenceFrequency.monthly) ...[
                const SizedBox(height: 16),
                FormBuilderDropdown<int>(
                  name: 'recurrenceDayOfMonth',
                  decoration: InputDecoration(
                    labelText: 'День месяца *',
                    border: const OutlineInputBorder(),
                    helperText: 'Например, каждое 5 число',
                    errorText: _fieldErrors['recurrenceDayOfMonth'],
                    errorMaxLines: 2,
                  ),
                  initialValue: _recurrenceDayOfMonth,
                  dropdownColor: context.appTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(
                    context.appTheme.borderRadius,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return List.generate(31, (index) => index + 1)
                        .map<Widget>((int day) {
                      return Text('$day число');
                    }).toList();
                  },
                  items: List.generate(31, (index) => index + 1)
                      .map(
                        (day) => createStyledDropdownItem<int>(
                          context: context,
                          value: day,
                          child: Text('$day число'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceDayOfMonth = value;
                    });
                  },
                  validator: FormBuilderValidators.required(
                    errorText: 'Выберите день месяца',
                  ),
                ),
              ],
              // Поле для выбора дней недели (только для weekly)
              if (_recurrenceFrequency == RecurrenceFrequency.weekly) ...[
                const SizedBox(height: 16),
                FormBuilderField<List<int>>(
                  name: 'daysOfWeek',
                  initialValue: _daysOfWeek,
                  builder: (FormFieldState<List<int>> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дни недели *',
                        border: const OutlineInputBorder(),
                        helperText: 'Выберите дни недели',
                        errorText: field.errorText ?? _fieldErrors['daysOfWeek'],
                        errorMaxLines: 2,
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (int i = 0; i < 7; i++)
                            FilterChip(
                              label: Text(_getDayOfWeekName(i)),
                              selected: _daysOfWeek?.contains(i) ?? false,
                              onSelected: (selected) {
                                setState(() {
                                  _daysOfWeek ??= [];
                                  if (selected) {
                                    _daysOfWeek!.add(i);
                                  } else {
                                    _daysOfWeek!.remove(i);
                                  }
                                  field.didChange(_daysOfWeek);
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Выберите хотя бы один день недели';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              // Дата начала
              FormBuilderDateTimePicker(
                name: 'startDate',
                initialValue: _startDate,
                decoration: InputDecoration(
                  labelText: 'Дата начала',
                  helperText: 'С какой даты начать создавать задачи (по умолчанию сегодня)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: _fieldErrors['startDate'],
                  errorMaxLines: 2,
                ),
                inputType: InputType.date,
                onChanged: (value) {
                  setState(() {
                    _startDate = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Дата окончания
              FormBuilderDateTimePicker(
                name: 'endDate',
                initialValue: _endDate,
                decoration: InputDecoration(
                  labelText: 'Дата окончания',
                  helperText: 'До какой даты создавать задачи (оставьте пустым для бесконечного создания)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: _fieldErrors['endDate'],
                  errorMaxLines: 2,
                ),
                inputType: InputType.date,
                onChanged: (value) {
                  setState(() {
                    _endDate = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Смещение дедлайна
              FormBuilderTextField(
                name: 'deadlineOffset',
                initialValue: _deadlineOffset?.toString(),
                decoration: InputDecoration(
                  labelText: 'Смещение дедлайна (часы)',
                  helperText: 'Смещение дедлайна в часах от времени создания (например, 8 = дедлайн в 17:00, если создается в 09:00)',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['deadlineOffset'],
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    final offset = int.tryParse(value);
                    if (offset != null) {
                      setState(() {
                        _deadlineOffset = offset;
                      });
                    }
                  } else {
                    setState(() {
                      _deadlineOffset = null;
                    });
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final offset = int.tryParse(value);
                    if (offset == null) {
                      return 'Введите число';
                    }
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 8),

            // Точка контроля
            FormBuilderCheckbox(
              name: 'isControlPoint',
              title: const Text('Точка контроля'),
              initialValue: _isControlPoint,
              onChanged: (value) {
                setState(() {
                  final newValue = value ?? false;
                  if (newValue && _isRecurring) {
                    // Если включаем точку контроля, выключаем регулярную задачу
                    _isRecurring = false;
                    _recurrenceFrequency = null;
                    _recurrenceInterval = 1;
                    _timeOfDay = null;
                    _daysOfWeek = null;
                    _recurrenceDayOfMonth = null;
                    _startDate = null;
                    _endDate = null;
                    _deadlineOffset = null;
                    _formKey.currentState?.fields['isRecurring']?.didChange(false);
                    _formKey.currentState?.fields['recurrenceFrequency']?.didChange(null);
                    _formKey.currentState?.fields['recurrenceInterval']?.didChange(null);
                    _formKey.currentState?.fields['timeOfDay']?.didChange(null);
                    _formKey.currentState?.fields['daysOfWeek']?.didChange(null);
                    _formKey.currentState?.fields['recurrenceDayOfMonth']?.didChange(null);
                    _formKey.currentState?.fields['startDate']?.didChange(null);
                    _formKey.currentState?.fields['endDate']?.didChange(null);
                    _formKey.currentState?.fields['deadlineOffset']?.didChange(null);
                  }
                  _isControlPoint = newValue;
                  // Очищаем метрики при выключении
                  if (!_isControlPoint) {
                    _metrics.clear();
                  }
                });
              },
            ),
            // Поля для настройки регулярности точки контроля (показываются только если точка контроля включена)
            if (_isControlPoint) ...[
              const SizedBox(height: 16),
              // Тип регулярности
              FormBuilderDropdown<RecurrenceFrequency>(
                name: 'recurrenceFrequency',
                decoration: InputDecoration(
                  labelText: 'Тип регулярности *',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['recurrenceFrequency'],
                  errorMaxLines: 2,
                ),
                initialValue: _recurrenceFrequency,
                dropdownColor: context.appTheme.backgroundSurface,
                borderRadius: BorderRadius.circular(
                  context.appTheme.borderRadius,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return RecurrenceFrequency.values
                      .map<Widget>((RecurrenceFrequency frequency) {
                    return Text(_getRecurrenceFrequencyText(frequency));
                  }).toList();
                },
                items: RecurrenceFrequency.values
                    .map(
                      (frequency) => createStyledDropdownItem<RecurrenceFrequency>(
                        context: context,
                        value: frequency,
                        child: Text(_getRecurrenceFrequencyText(frequency)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _recurrenceFrequency = value;
                    // Очищаем специфичные поля при смене типа регулярности
                    if (value != RecurrenceFrequency.monthly) {
                      _recurrenceDayOfMonth = null;
                      _formKey.currentState?.fields['recurrenceDayOfMonth']?.didChange(null);
                    }
                    if (value != RecurrenceFrequency.weekly) {
                      _daysOfWeek = null;
                      _formKey.currentState?.fields['daysOfWeek']?.didChange(null);
                    }
                  });
                },
                validator: FormBuilderValidators.required(
                  errorText: 'Выберите тип регулярности',
                ),
              ),
              const SizedBox(height: 16),
              // Интервал
              FormBuilderTextField(
                name: 'recurrenceInterval',
                initialValue: _recurrenceInterval.toString(),
                decoration: InputDecoration(
                  labelText: 'Интервал',
                  helperText: 'Каждые N дней/недель/месяцев (по умолчанию 1)',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['recurrenceInterval'],
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    final interval = int.tryParse(value);
                    if (interval != null && interval > 0) {
                      setState(() {
                        _recurrenceInterval = interval;
                      });
                    }
                  }
                },
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.numeric(),
                  FormBuilderValidators.min(1, errorText: 'Интервал должен быть больше 0'),
                ]),
              ),
              const SizedBox(height: 16),
              // Время создания задачи
              FormBuilderTextField(
                name: 'timeOfDay',
                initialValue: _timeOfDay,
                decoration: InputDecoration(
                  labelText: 'Время создания задачи',
                  helperText: 'Формат: HH:MM (например, 09:00)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                  errorText: _fieldErrors['timeOfDay'],
                  errorMaxLines: 2,
                ),
                onChanged: (value) {
                  setState(() {
                    _timeOfDay = value;
                  });
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
                    if (!timeRegex.hasMatch(value)) {
                      return 'Неверный формат времени. Используйте HH:MM';
                    }
                  }
                  return null;
                },
              ),
              // Поле для выбора дня месяца (только для monthly)
              if (_recurrenceFrequency == RecurrenceFrequency.monthly) ...[
                const SizedBox(height: 16),
                FormBuilderDropdown<int>(
                  name: 'recurrenceDayOfMonth',
                  decoration: InputDecoration(
                    labelText: 'День месяца *',
                    border: const OutlineInputBorder(),
                    helperText: 'Например, каждое 5 число',
                    errorText: _fieldErrors['recurrenceDayOfMonth'],
                    errorMaxLines: 2,
                  ),
                  initialValue: _recurrenceDayOfMonth,
                  dropdownColor: context.appTheme.backgroundSurface,
                  borderRadius: BorderRadius.circular(
                    context.appTheme.borderRadius,
                  ),
                  selectedItemBuilder: (BuildContext context) {
                    return List.generate(31, (index) => index + 1)
                        .map<Widget>((int day) {
                      return Text('$day число');
                    }).toList();
                  },
                  items: List.generate(31, (index) => index + 1)
                      .map(
                        (day) => createStyledDropdownItem<int>(
                          context: context,
                          value: day,
                          child: Text('$day число'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _recurrenceDayOfMonth = value;
                    });
                  },
                  validator: FormBuilderValidators.required(
                    errorText: 'Выберите день месяца',
                  ),
                ),
              ],
              // Поле для выбора дней недели (только для weekly)
              if (_recurrenceFrequency == RecurrenceFrequency.weekly) ...[
                const SizedBox(height: 16),
                FormBuilderField<List<int>>(
                  name: 'daysOfWeek',
                  initialValue: _daysOfWeek,
                  builder: (FormFieldState<List<int>> field) {
                    return InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Дни недели *',
                        border: const OutlineInputBorder(),
                        helperText: 'Выберите дни недели',
                        errorText: field.errorText ?? _fieldErrors['daysOfWeek'],
                        errorMaxLines: 2,
                      ),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (int i = 0; i < 7; i++)
                            FilterChip(
                              label: Text(_getDayOfWeekName(i)),
                              selected: _daysOfWeek?.contains(i) ?? false,
                              onSelected: (selected) {
                                setState(() {
                                  _daysOfWeek ??= [];
                                  if (selected) {
                                    _daysOfWeek!.add(i);
                                  } else {
                                    _daysOfWeek!.remove(i);
                                  }
                                  field.didChange(_daysOfWeek);
                                });
                              },
                            ),
                        ],
                      ),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Выберите хотя бы один день недели';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              // Дата начала
              FormBuilderDateTimePicker(
                name: 'startDate',
                initialValue: _startDate,
                decoration: InputDecoration(
                  labelText: 'Дата начала',
                  helperText: 'С какой даты начать создавать задачи (по умолчанию сегодня)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: _fieldErrors['startDate'],
                  errorMaxLines: 2,
                ),
                inputType: InputType.date,
                onChanged: (value) {
                  setState(() {
                    _startDate = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Дата окончания
              FormBuilderDateTimePicker(
                name: 'endDate',
                initialValue: _endDate,
                decoration: InputDecoration(
                  labelText: 'Дата окончания',
                  helperText: 'До какой даты создавать задачи (оставьте пустым для бесконечного создания)',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                  errorText: _fieldErrors['endDate'],
                  errorMaxLines: 2,
                ),
                inputType: InputType.date,
                onChanged: (value) {
                  setState(() {
                    _endDate = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Смещение дедлайна
              FormBuilderTextField(
                name: 'deadlineOffset',
                initialValue: _deadlineOffset?.toString(),
                decoration: InputDecoration(
                  labelText: 'Смещение дедлайна (часы)',
                  helperText: 'Смещение дедлайна в часах от времени создания (например, 8 = дедлайн в 17:00, если создается в 09:00)',
                  border: const OutlineInputBorder(),
                  errorText: _fieldErrors['deadlineOffset'],
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    final offset = int.tryParse(value);
                    if (offset != null) {
                      setState(() {
                        _deadlineOffset = offset;
                      });
                    }
                  } else {
                    setState(() {
                      _deadlineOffset = null;
                    });
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final offset = int.tryParse(value);
                    if (offset == null) {
                      return 'Введите число';
                    }
                  }
                  return null;
                },
              ),
            ],
            // Поля для метрик (показываются только если точка контроля)
            if (_isControlPoint) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Метрики *',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () {
                      setState(() {
                        _metrics.add(_ControlPointMetric());
                      });
                    },
                    tooltip: 'Добавить метрику',
                  ),
                ],
              ),
              if (_metrics.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Добавьте хотя бы одну метрику',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ..._metrics.asMap().entries.map((entry) {
                final index = entry.key;
                final metric = entry.value;
                return _buildMetricCard(index, metric);
              }),
            ],
            // const SizedBox(height: 8),

            // // Не забыть выполнить
            // FormBuilderCheckbox(
            //   name: 'dontForget',
            //   title: const Text('Заметки на ходу'),
            //   initialValue: _dontForget,
            //   onChanged: (value) {
            //     setState(() {
            //       _dontForget = value ?? false;
            //     });
            //   },
            // ),
            const SizedBox(height: 24),

            // Инициатор (автоматически устанавливается текущий пользователь)
            // Используем UserSelectorWidget для единообразия и правильной загрузки сотрудников
            Builder(
              builder: (context) {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final currentUserId = authProvider.user?.id;
                final initiatorId = _assignedById ?? currentUserId;
                
                return AbsorbPointer(
                  // Блокируем взаимодействие, так как поле read-only
                  child: Opacity(
                    opacity: 0.7, // Визуально показываем, что поле неактивно
                    child: UserSelectorWidget(
                      businessId: widget.businessId,
                      userRepository: widget.userRepository,
                      selectedUserId: initiatorId,
                      onUserSelected: (_) {
                        // Игнорируем изменения, так как поле read-only
                      },
                      label: 'Инициатор',
                    ),
                  ),
                );
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

    // Валидация для точки контроля
    if (_isControlPoint) {
      if (_recurrenceFrequency == null) {
        setState(() {
          _fieldErrors['recurrenceFrequency'] = 'Выберите тип регулярности';
        });
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }
      if (_metrics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Добавьте хотя бы одну метрику для точки контроля'),
            backgroundColor: Colors.red,
          ),
        );
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        return;
      }
      // Валидация метрик
      for (int i = 0; i < _metrics.length; i++) {
        final metric = _metrics[i];
        if (metric.name.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заполните название метрики ${i + 1}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (metric.targetValue == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заполните целевое значение метрики ${i + 1}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (metric.unit == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Выберите единицу измерения для метрики ${i + 1}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (metric.unit == MeasurementUnit.custom && (metric.customUnit == null || metric.customUnit!.isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Заполните кастомную единицу для метрики ${i + 1}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    }

    // Валидация для регулярной задачи
    if (_isRecurring && _recurrenceFrequency == null) {
      setState(() {
        _fieldErrors['recurrenceFrequency'] = 'Выберите тип регулярности';
      });
      if (mounted) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    // Если пользователь не может изменять исполнителя и checkbox включен, устанавливаем текущего пользователя
    if (!_canChangeAssignee() && _isMeAssignee) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserId = authProvider.user?.id;
      if (currentUserId != null) {
        _assignedToId = currentUserId;
      }
    }

    // Всегда устанавливаем текущего пользователя как инициатора
    _setCurrentUserAsInitiator();

    // Сохраняем значения из UserSelectorWidget
    _formKey.currentState?.fields['assignedTo']?.didChange(_assignedToId);
    _formKey.currentState?.fields['assignedBy']?.didChange(_assignedById);

    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;

      // Создаем recurrence, если задача регулярная или точка контроля
      TaskRecurrence? recurrence;
      if ((_isRecurring || _isControlPoint) && _recurrenceFrequency != null) {
        // Для создания задачи используем временные id и taskId
        // Они будут заменены на сервере
        recurrence = TaskRecurrence(
          id: '', // Будет присвоен на сервере
          taskId: '', // Будет присвоен на сервере
          frequency: _recurrenceFrequency!,
          interval: _recurrenceInterval,
          endDate: _endDate,
          daysOfWeek: _daysOfWeek,
          dayOfMonth: _recurrenceFrequency == RecurrenceFrequency.monthly
              ? _recurrenceDayOfMonth
              : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Создаем метрики для точки контроля
      List<Map<String, dynamic>>? controlPointMetrics;
      if (_isControlPoint && _metrics.isNotEmpty) {
        controlPointMetrics = _metrics.map((metric) {
          return {
            'name': metric.name,
            'targetValue': metric.targetValue,
            'unit': TaskModel.measurementUnitToString(metric.unit!),
            if (metric.unit == MeasurementUnit.custom && metric.customUnit != null)
              'customUnit': metric.customUnit,
            if (metric.sortOrder != null) 'sortOrder': metric.sortOrder,
          };
        }).toList();
      }

      // Создаем TaskModel с дополнительными данными для создания
      final taskModel = TaskModel(
        id: '', // Будет присвоен на сервере
        businessId: widget.businessId,
        title: formData['title'] as String,
        description: formData['description'] as String?,
        status: formData['status'] as TaskStatus? ?? TaskStatus.inProgress,
        assignedTo: _assignedToId,
        assignedBy: _assignedById,
        assignmentDate:
            DateTime.now(), // Всегда текущая дата/время при создании
        deadline: (!_isRecurring && !_isControlPoint) ? formData['deadline'] as DateTime? : null,
        isImportant: formData['isImportant'] as bool? ?? false,
        isRecurring: _isRecurring,
        hasControlPoint: _isControlPoint,
        dontForget: false, // Поле закомментировано
        customerId: widget.customerId,
        recurrence: recurrence,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        timeOfDay: _timeOfDay,
        startDate: _startDate,
        deadlineOffset: _deadlineOffset,
        controlPointMetrics: controlPointMetrics,
      );

      widget.onSubmit(taskModel);
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

  String _getRecurrenceFrequencyText(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Ежедневно';
      case RecurrenceFrequency.weekly:
        return 'Еженедельно';
      case RecurrenceFrequency.monthly:
        return 'Ежемесячно';
      case RecurrenceFrequency.yearly:
        return 'Ежегодно';
    }
  }

  String _getDayOfWeekName(int day) {
    switch (day) {
      case 0:
        return 'Вс';
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      default:
        return '';
    }
  }

  String _getMeasurementUnitText(MeasurementUnit unit) {
    switch (unit) {
      case MeasurementUnit.kilogram:
        return 'Килограмм';
      case MeasurementUnit.gram:
        return 'Грамм';
      case MeasurementUnit.ton:
        return 'Тонна';
      case MeasurementUnit.meter:
        return 'Метр';
      case MeasurementUnit.kilometer:
        return 'Километр';
      case MeasurementUnit.hour:
        return 'Час';
      case MeasurementUnit.minute:
        return 'Минута';
      case MeasurementUnit.piece:
        return 'Штука';
      case MeasurementUnit.liter:
        return 'Литр';
      case MeasurementUnit.custom:
        return 'Кастомная';
    }
  }

  Widget _buildMetricCard(int index, _ControlPointMetric metric) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Метрика ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _metrics.removeAt(index);
                    });
                  },
                  tooltip: 'Удалить метрику',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Название метрики
            TextFormField(
              initialValue: metric.name,
              decoration: const InputDecoration(
                labelText: 'Название метрики *',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                metric.name = value;
              },
            ),
            const SizedBox(height: 16),
            // Целевое значение
            TextFormField(
              initialValue: metric.targetValue?.toString(),
              decoration: const InputDecoration(
                labelText: 'Целевое значение *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  metric.targetValue = double.tryParse(value);
                } else {
                  metric.targetValue = null;
                }
              },
            ),
            const SizedBox(height: 16),
            // Единица измерения
            DropdownButtonFormField<MeasurementUnit>(
              value: metric.unit,
              decoration: const InputDecoration(
                labelText: 'Единица измерения *',
                border: OutlineInputBorder(),
              ),
              items: MeasurementUnit.values.map((unit) {
                return DropdownMenuItem(
                  value: unit,
                  child: Text(_getMeasurementUnitText(unit)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  metric.unit = value;
                  if (value != MeasurementUnit.custom) {
                    metric.customUnit = null;
                  }
                });
              },
            ),
            // Кастомная единица (если выбрана CUSTOM)
            if (metric.unit == MeasurementUnit.custom) ...[
              const SizedBox(height: 16),
              TextFormField(
                initialValue: metric.customUnit,
                decoration: const InputDecoration(
                  labelText: 'Кастомная единица *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  metric.customUnit = value;
                },
              ),
            ],
            const SizedBox(height: 16),
            // Порядок отображения
            TextFormField(
              initialValue: metric.sortOrder?.toString(),
              decoration: const InputDecoration(
                labelText: 'Порядок отображения',
                border: OutlineInputBorder(),
                helperText: 'Число для сортировки (по умолчанию по порядку добавления)',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  metric.sortOrder = int.tryParse(value);
                } else {
                  metric.sortOrder = null;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Временный класс для хранения метрики точки контроля в форме
class _ControlPointMetric {
  String name = '';
  double? targetValue;
  MeasurementUnit? unit;
  String? customUnit;
  int? sortOrder;

  _ControlPointMetric();
}
