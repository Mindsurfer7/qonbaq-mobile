import 'package:flutter/material.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_task_by_id.dart';
import '../../domain/usecases/create_task_comment.dart';
import '../../domain/usecases/delete_task_comment.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../widgets/user_selector_widget.dart';
import '../widgets/comment_section.dart';
import '../widgets/comment_item.dart';
import '../widgets/user_info_row.dart';
import '../../domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart' hide State, Task;

/// Детальная страница задачи
class TaskDetailPage extends StatefulWidget {
  final String taskId;

  const TaskDetailPage({
    super.key,
    required this.taskId,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  Task? _task;
  bool _isLoading = true;
  String? _error;
  bool _isEditing = false;
  final ScrollController _scrollController = ScrollController();
  final _formKey = GlobalKey<FormBuilderState>();
  String? _assignedToId;
  String? _assignedById;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getTaskUseCase = Provider.of<GetTaskById>(context, listen: false);
    final result = await getTaskUseCase.call(widget.taskId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке задачи'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (task) {
        setState(() {
          _isLoading = false;
          _task = task;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
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

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (taskDate == today) {
      return 'Сегодня ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Завтра ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getUserDisplayName(ProfileUser user) {
    final parts = <String>[];
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      parts.add(user.firstName!);
    }
    if (user.patronymic != null && user.patronymic!.isNotEmpty) {
      parts.add(user.patronymic!);
    }
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  Future<void> _saveTask() async {
    if (_task == null || _formKey.currentState == null) return;

    if (!(_formKey.currentState!.saveAndValidate())) {
      return;
    }

    final formData = _formKey.currentState!.value;

    // Создаем обновленную задачу
    final updatedTask = Task(
      id: _task!.id,
      businessId: _task!.businessId,
      title: formData['title'] as String,
      description: formData['description'] as String?,
      status: formData['status'] as TaskStatus? ?? _task!.status,
      priority: formData['priority'] as TaskPriority?,
      assignedTo: _assignedToId ?? _task!.assignedTo,
      assignedBy: _assignedById ?? _task!.assignedBy,
      assignmentDate: formData['assignmentDate'] as DateTime? ?? _task!.assignmentDate,
      deadline: formData['deadline'] as DateTime? ?? _task!.deadline,
      isImportant: formData['isImportant'] as bool? ?? _task!.isImportant,
      isRecurring: formData['isRecurring'] as bool? ?? _task!.isRecurring,
      hasControlPoint: formData['hasControlPoint'] as bool? ?? _task!.hasControlPoint,
      dontForget: formData['dontForget'] as bool? ?? _task!.dontForget,
      voiceNoteUrl: formData['voiceNoteUrl'] as String? ?? _task!.voiceNoteUrl,
      resultText: _task!.resultText,
      createdAt: _task!.createdAt,
      updatedAt: DateTime.now(),
      observerIds: _task!.observerIds,
      attachments: _task!.attachments,
      indicators: _task!.indicators,
      recurrence: _task!.recurrence,
      business: _task!.business,
      assignee: _task!.assignee,
      assigner: _task!.assigner,
      observers: _task!.observers,
      comments: _task!.comments,
    );

    final updateTaskUseCase = Provider.of<UpdateTask>(context, listen: false);
    final result = await updateTaskUseCase.call(
      UpdateTaskParams(id: _task!.id, task: updatedTask),
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (task) {
        setState(() {
          _task = task;
          _isEditing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Задача обновлена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _assignedToId = null;
      _assignedById = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task?.title ?? 'Задача'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _assignedToId = _task?.assignedTo;
                  _assignedById = _task?.assignedBy;
                });
              },
              tooltip: 'Редактировать',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTask,
            tooltip: 'Обновить',
          ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTask,
              tooltip: 'Сохранить',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Отмена',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadTask,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _task == null
                  ? const Center(child: Text('Задача не найдена'))
                  : _isEditing
                      ? _buildEditView()
                      : _buildDetailView(),
    );
  }

  Widget _buildEditView() {
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    
    return FormBuilder(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormBuilderTextField(
              name: 'title',
              initialValue: _task!.title,
              decoration: const InputDecoration(
                labelText: 'Название задачи *',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.required(
                errorText: 'Название задачи обязательно',
              ),
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'description',
              initialValue: _task!.description,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FormBuilderDropdown<TaskPriority>(
              name: 'priority',
              initialValue: _task!.priority,
              decoration: const InputDecoration(
                labelText: 'Приоритет',
                border: OutlineInputBorder(),
              ),
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(context.appTheme.borderRadius),
              selectedItemBuilder: (BuildContext context) {
                return TaskPriority.values.map<Widget>((TaskPriority priority) {
                  return Text(_getPriorityText(priority));
                }).toList();
              },
              items: TaskPriority.values.map((priority) => createStyledDropdownItem<TaskPriority>(
                context: context,
                value: priority,
                child: Text(_getPriorityText(priority)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            FormBuilderDropdown<TaskStatus>(
              name: 'status',
              initialValue: _task!.status,
              decoration: const InputDecoration(
                labelText: 'Статус',
                border: OutlineInputBorder(),
              ),
              dropdownColor: context.appTheme.backgroundSurface,
              borderRadius: BorderRadius.circular(context.appTheme.borderRadius),
              selectedItemBuilder: (BuildContext context) {
                return TaskStatus.values.map<Widget>((TaskStatus status) {
                  return Text(_getStatusText(status));
                }).toList();
              },
              items: TaskStatus.values.map((status) => createStyledDropdownItem<TaskStatus>(
                context: context,
                value: status,
                child: Text(_getStatusText(status)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            UserSelectorWidget(
              businessId: _task!.businessId,
              userRepository: userRepository,
              selectedUserId: _assignedToId,
              onUserSelected: (userId) {
                setState(() {
                  _assignedToId = userId;
                });
              },
              label: 'Исполнитель',
            ),
            const SizedBox(height: 16),
            UserSelectorWidget(
              businessId: _task!.businessId,
              userRepository: userRepository,
              selectedUserId: _assignedById,
              onUserSelected: (userId) {
                setState(() {
                  _assignedById = userId;
                });
              },
              label: 'Поручитель',
            ),
            const SizedBox(height: 16),
            FormBuilderDateTimePicker(
              name: 'assignmentDate',
              initialValue: _task!.assignmentDate,
              decoration: const InputDecoration(
                labelText: 'Дата поручения',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              inputType: InputType.both,
            ),
            const SizedBox(height: 16),
            FormBuilderDateTimePicker(
              name: 'deadline',
              initialValue: _task!.deadline,
              decoration: const InputDecoration(
                labelText: 'Дедлайн',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.event),
              ),
              inputType: InputType.both,
            ),
            const SizedBox(height: 16),
            FormBuilderCheckbox(
              name: 'isImportant',
              title: const Text('Важная задача'),
              initialValue: _task!.isImportant,
            ),
            const SizedBox(height: 8),
            FormBuilderCheckbox(
              name: 'isRecurring',
              title: const Text('Регулярная задача'),
              initialValue: _task!.isRecurring,
            ),
            const SizedBox(height: 8),
            FormBuilderCheckbox(
              name: 'hasControlPoint',
              title: const Text('Задача с точкой контроля'),
              initialValue: _task!.hasControlPoint,
            ),
            const SizedBox(height: 8),
            FormBuilderCheckbox(
              name: 'dontForget',
              title: const Text('Не забыть выполнить'),
              initialValue: _task!.dontForget,
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'voiceNoteUrl',
              initialValue: _task!.voiceNoteUrl,
              decoration: const InputDecoration(
                labelText: 'URL голосовой заметки',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailView() {
    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadTask,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок и статус
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _task!.title,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_task!.status),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _getStatusText(_task!.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Приоритет и важность
                                  if (_task!.priority != null ||
                                      _task!.isImportant)
                                    Row(
                                      children: [
                                        if (_task!.priority != null) ...[
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(
                                                  _task!.priority!),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _getPriorityText(_task!.priority!),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        if (_task!.isImportant)
                                          const Icon(Icons.star,
                                              color: Colors.amber, size: 24),
                                        if (_task!.dontForget) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.notifications_active,
                                              color: Colors.orange, size: 24),
                                        ],
                                      ],
                                    ),
                                  const SizedBox(height: 16),

                                  // Описание
                                  if (_task!.description != null &&
                                      _task!.description!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Описание',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _task!.description!,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Компания
                                  if (_task!.business != null)
                                    _buildInfoRow(
                                      'Компания',
                                      _task!.business!.name,
                                      Icons.business,
                                    ),

                                  // Исполнитель
                                  if (_task!.assignee != null)
                                    Builder(
                                      builder: (context) {
                                        final chatRepository = Provider.of<ChatRepository>(
                                          context,
                                          listen: false,
                                        );
                                        return UserInfoRow(
                                          user: _task!.assignee,
                                          label: 'Исполнитель',
                                          icon: Icons.person,
                                          chatRepository: chatRepository,
                                        );
                                      },
                                    ),

                                  // Поручитель
                                  if (_task!.assigner != null)
                                    Builder(
                                      builder: (context) {
                                        final chatRepository = Provider.of<ChatRepository>(
                                          context,
                                          listen: false,
                                        );
                                        return UserInfoRow(
                                          user: _task!.assigner,
                                          label: 'Поручил',
                                          icon: Icons.person_outline,
                                          chatRepository: chatRepository,
                                        );
                                      },
                                    ),

                                  // Дата назначения
                                  if (_task!.assignmentDate != null)
                                    _buildInfoRow(
                                      'Дата назначения',
                                      _formatDateTime(_task!.assignmentDate!),
                                      Icons.calendar_today,
                                    ),

                                  // Срок выполнения
                                  if (_task!.deadline != null)
                                    _buildInfoRow(
                                      'Срок выполнения',
                                      _formatDateTime(_task!.deadline!),
                                      _task!.deadline!.isBefore(DateTime.now())
                                          ? Icons.warning
                                          : Icons.event,
                                      color: _task!.deadline!.isBefore(
                                              DateTime.now())
                                          ? Colors.red
                                          : null,
                                    ),

                                  // Наблюдатели
                                  if (_task!.observers != null &&
                                      _task!.observers!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Наблюдатели',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_task!.observers!
                                            .map((obs) => Padding(
                                                  padding: const EdgeInsets.only(
                                                      bottom: 4),
                                                  child: Text(
                                                    _getUserDisplayName(obs.user),
                                                    style: const TextStyle(
                                                        fontSize: 16),
                                                  ),
                                                ))),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Вложения
                                  if (_task!.attachments != null &&
                                      _task!.attachments!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Вложения',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_task!.attachments!.map((att) =>
                                            ListTile(
                                              leading: const Icon(Icons.attach_file),
                                              title: Text(att.fileName ??
                                                  'Без имени'),
                                              subtitle: Text(att.fileType ?? ''),
                                              trailing: att.isResult
                                                  ? const Chip(
                                                      label: Text('Результат'),
                                                      backgroundColor:
                                                          Colors.green,
                                                    )
                                                  : null,
                                            ))),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Результат
                                  if (_task!.resultText != null &&
                                      _task!.resultText!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Результат выполнения',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green.shade200),
                                          ),
                                          child: Text(
                                            _task!.resultText!,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Комментарии
                                  CommentSection(
                                    comments: _task!.comments != null
                                        ? CommentItem.fromTaskComments(_task!.comments!)
                                        : [],
                                    onCreateComment: (text) async {
                                      final createCommentUseCase =
                                          Provider.of<CreateTaskComment>(
                                        context,
                                        listen: false,
                                      );
                                      final result = await createCommentUseCase.call(
                                        CreateTaskCommentParams(
                                          taskId: _task!.id,
                                          text: text,
                                        ),
                                      );
                                      return result.map((_) => null);
                                    },
                                    onDeleteComment: (commentId) async {
                                      final deleteCommentUseCase =
                                          Provider.of<DeleteTaskComment>(
                                        context,
                                        listen: false,
                                      );
                                      return await deleteCommentUseCase.call(
                                        DeleteTaskCommentParams(
                                          taskId: _task!.id,
                                          commentId: commentId,
                                        ),
                                      );
                                    },
                                    onRefresh: _loadTask,
                                    chatRepository: Provider.of<ChatRepository>(
                                      context,
                                      listen: false,
                                    ),
                                    showChatButton: true,
                              ),
                            ],
                          ),
                            ),
                          ),
                        ),
                      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

