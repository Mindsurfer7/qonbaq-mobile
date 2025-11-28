import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/user_repository.dart';
import 'user_selector_widget.dart';

/// Форма создания задачи
class CreateTaskForm extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final Function(Task) onSubmit;
  final VoidCallback onCancel;
  final String? error; // Ошибка от сервера
  final Function(String)? onError; // Callback для обновления ошибки

  const CreateTaskForm({
    super.key,
    required this.businessId,
    required this.userRepository,
    required this.onSubmit,
    required this.onCancel,
    this.error,
    this.onError,
  });

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isImportant = false;
  bool _isRecurring = false;
  bool _hasControlPoint = false;
  String? _assignedToId;
  String? _assignedById;

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
            // Заголовок
            FormBuilderTextField(
              name: 'title',
              decoration: const InputDecoration(
                labelText: 'Название задачи *',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.required(
                errorText: 'Название задачи обязательно',
              ),
            ),
            const SizedBox(height: 16),

            // Описание
            FormBuilderTextField(
              name: 'description',
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Приоритет
            FormBuilderDropdown<TaskPriority>(
              name: 'priority',
              decoration: const InputDecoration(
                labelText: 'Приоритет',
                border: OutlineInputBorder(),
              ),
              items:
                  TaskPriority.values
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(_getPriorityText(priority)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Статус
            FormBuilderDropdown<TaskStatus>(
              name: 'status',
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              initialValue: TaskStatus.pending,
              items:
                  TaskStatus.values
                      .map(
                        (status) => DropdownMenuItem(
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

            // Дата поручения
            FormBuilderDateTimePicker(
              name: 'assignmentDate',
              decoration: const InputDecoration(
                labelText: 'Дата поручения',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              inputType: InputType.both,
            ),
            const SizedBox(height: 16),

            // Дедлайн
            FormBuilderDateTimePicker(
              name: 'deadline',
              decoration: const InputDecoration(
                labelText: 'Дедлайн',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.event),
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
            const SizedBox(height: 16),

            // URL голосовой заметки
            FormBuilderTextField(
              name: 'voiceNoteUrl',
              decoration: const InputDecoration(
                labelText: 'URL голосовой заметки',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ID наблюдателей (через запятую)
            FormBuilderTextField(
              name: 'observerIds',
              decoration: const InputDecoration(
                labelText: 'ID наблюдателей',
                border: OutlineInputBorder(),
                hintText: 'Введите ID через запятую',
                helperText: 'Разделите ID запятой, например: id1,id2,id3',
              ),
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
        status: formData['status'] as TaskStatus? ?? TaskStatus.pending,
        priority: formData['priority'] as TaskPriority?,
        assignedTo: _assignedToId,
        assignedBy: _assignedById,
        assignmentDate: formData['assignmentDate'] as DateTime?,
        deadline: formData['deadline'] as DateTime?,
        isImportant: formData['isImportant'] as bool? ?? false,
        isRecurring: formData['isRecurring'] as bool? ?? false,
        hasControlPoint: formData['hasControlPoint'] as bool? ?? false,
        voiceNoteUrl: formData['voiceNoteUrl'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        observerIds: _parseObserverIds(formData['observerIds'] as String?),
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

  List<String>? _parseObserverIds(String? observerIdsString) {
    if (observerIdsString == null || observerIdsString.trim().isEmpty) {
      return null;
    }
    final ids =
        observerIdsString
            .split(',')
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList();
    return ids.isEmpty ? null : ids;
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.urgent:
        return 'Срочный';
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
}
