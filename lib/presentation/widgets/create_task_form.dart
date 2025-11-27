import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/task.dart';

/// Форма создания задачи
class CreateTaskForm extends StatefulWidget {
  final String businessId;
  final Function(Task) onSubmit;
  final VoidCallback onCancel;

  const CreateTaskForm({
    super.key,
    required this.businessId,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<CreateTaskForm> createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isImportant = false;
  bool _isRecurring = false;
  bool _hasControlPoint = false;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              items: TaskPriority.values
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(_getPriorityText(priority)),
                      ))
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
              items: TaskStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Исполнитель (ID)
            FormBuilderTextField(
              name: 'assignedTo',
              decoration: const InputDecoration(
                labelText: 'ID исполнителя',
                border: OutlineInputBorder(),
                hintText: 'Введите ID пользователя',
              ),
            ),
            const SizedBox(height: 16),

            // Поручитель (ID)
            FormBuilderTextField(
              name: 'assignedBy',
              decoration: const InputDecoration(
                labelText: 'ID поручителя',
                border: OutlineInputBorder(),
                hintText: 'Введите ID пользователя',
              ),
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
        assignedTo: formData['assignedTo'] as String?,
        assignedBy: formData['assignedBy'] as String?,
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
    }
  }

  List<String>? _parseObserverIds(String? observerIdsString) {
    if (observerIdsString == null || observerIdsString.trim().isEmpty) {
      return null;
    }
    final ids = observerIdsString
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

