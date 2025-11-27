import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import '../widgets/create_task_form.dart';
import '../widgets/business_selector_widget.dart';

/// Страница задач
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  bool _isLoadingTasks = false;
  String? _error;
  List<Task> _tasks = [];

  void _showCreateTaskDialog(CreateTask createTaskUseCase, String businessId) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
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
                          'Создать задачу',
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
                    child: CreateTaskForm(
                      businessId: businessId,
                      onSubmit:
                          (task) => _handleCreateTask(task, createTaskUseCase),
                      onCancel: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _handleCreateTask(
    Task task,
    CreateTask createTaskUseCase,
  ) async {
    setState(() {
      _error = null;
    });

    final result = await createTaskUseCase.call(CreateTaskParams(task: task));

    result.fold(
      (failure) {
        setState(() {
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при создании задачи'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (createdTask) {
        if (mounted) {
          Navigator.of(context).pop(); // Закрываем диалог
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Задача успешно создана'),
              backgroundColor: Colors.green,
            ),
          );
          // Обновляем список задач
          final profileProvider = Provider.of<ProfileProvider>(
            context,
            listen: false,
          );
          final selectedBusiness = profileProvider.selectedBusiness;
          final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
          if (selectedBusiness != null) {
            _loadTasks(getTasksUseCase, selectedBusiness.id);
          }
        }
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

  Future<void> _loadTasks(GetTasks getTasksUseCase, String? businessId) async {
    setState(() {
      _isLoadingTasks = true;
      _error = null;
    });

    final result = await getTasksUseCase.call(
      GetTasksParams(businessId: businessId, limit: 50),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingTasks = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке задач'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (tasks) {
        setState(() {
          _isLoadingTasks = false;
          _tasks = tasks;
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Загружаем задачи после инициализации виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final selectedBusiness = profileProvider.selectedBusiness;
      final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
      if (selectedBusiness != null) {
        _loadTasks(getTasksUseCase, selectedBusiness.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context);
    final getTasksUseCase = Provider.of<GetTasks>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selectedBusiness != null) {
                _loadTasks(getTasksUseCase, selectedBusiness.id);
              }
            },
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: selectedBusiness == null
          ? _buildBusinessSelectionView(profileProvider)
          : _buildTasksView(selectedBusiness, getTasksUseCase),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (selectedBusiness != null) {
                          _loadTasks(getTasksUseCase, selectedBusiness.id);
                        }
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : _tasks.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Нет задач',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Нажмите + чтобы создать задачу',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: () async {
                  if (selectedBusiness != null) {
                    await _loadTasks(getTasksUseCase, selectedBusiness.id);
                  }
                },
                child: ListView.builder(
                  itemCount: _tasks.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: _getStatusIcon(task.status),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration:
                                task.status == TaskStatus.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (task.description != null &&
                                task.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  task.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (task.priority != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(task.priority!),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getPriorityText(task.priority!),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                if (task.priority != null)
                                  const SizedBox(width: 8),
                                if (task.isImportant)
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                if (task.deadline != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.event,
                                    size: 16,
                                    color:
                                        _isDeadlineOverdue(task.deadline!)
                                            ? Colors.red
                                            : Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(task.deadline!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          _isDeadlineOverdue(task.deadline!)
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: _getStatusChip(task.status),
                        onTap: () {
                          // TODO: Переход на страницу деталей задачи
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton:
          selectedBusiness != null
              ? FloatingActionButton(
                onPressed: () {
                  _showCreateTaskDialog(createTaskUseCase, selectedBusiness.id);
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    IconData icon;
    Color color;
    switch (status) {
      case TaskStatus.pending:
        icon = Icons.pending;
        color = Colors.grey;
        break;
      case TaskStatus.inProgress:
        icon = Icons.play_circle_outline;
        color = Colors.blue;
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case TaskStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.red;
        break;
    }
    return Icon(icon, color: color);
  }

  Widget _getStatusChip(TaskStatus status) {
    return Chip(
      label: Text(_getStatusText(status)),
      backgroundColor: _getStatusColor(status),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
    );
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Сегодня';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Завтра';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  bool _isDeadlineOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  /// Вид для выбора компании (когда бизнес не выбран)
  Widget _buildBusinessSelectionView(ProfileProvider profileProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Плашка с сообщением
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business_center,
                  size: 48,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Необходимо выбрать компанию',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Для работы с задачами выберите компанию из списка',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Виджет выбора компании
          const BusinessSelectorWidget(compact: false),
        ],
      ),
    );
  }

  /// Вид со списком задач (когда бизнес выбран)
  Widget _buildTasksView(Business selectedBusiness, GetTasks getTasksUseCase) {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadTasks(getTasksUseCase, selectedBusiness.id);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет задач',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажмите + чтобы создать задачу',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTasks(getTasksUseCase, selectedBusiness.id);
      },
      child: ListView.builder(
        itemCount: _tasks.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            child: ListTile(
              leading: _getStatusIcon(task.status),
              title: Text(
                task.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: task.status == TaskStatus.completed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description != null &&
                      task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (task.priority != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getPriorityText(task.priority!),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (task.priority != null)
                        const SizedBox(width: 8),
                      if (task.isImportant)
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                      if (task.deadline != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.event,
                          size: 16,
                          color: _isDeadlineOverdue(task.deadline!)
                              ? Colors.red
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(task.deadline!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _isDeadlineOverdue(task.deadline!)
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: _getStatusChip(task.status),
              onTap: () {
                // TODO: Переход на страницу деталей задачи
              },
            ),
          );
        },
      ),
    );
  }
}
