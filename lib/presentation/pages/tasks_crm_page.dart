import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';

/// Страница задач по клиентам CRM
class TasksCrmPage extends StatefulWidget {
  const TasksCrmPage({super.key});

  @override
  State<TasksCrmPage> createState() => _TasksCrmPageState();
}

class _TasksCrmPageState extends State<TasksCrmPage> {
  bool _isLoadingTasks = false;
  String? _error;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    // Загружаем задачи после инициализации виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);

    if (selectedBusiness == null) {
      setState(() {
        _error = 'Необходимо выбрать компанию';
      });
      return;
    }

    setState(() {
      _isLoadingTasks = true;
      _error = null;
    });

    final result = await getTasksUseCase.call(
      GetTasksParams(
        businessId: selectedBusiness.id,
        hasCustomer: true, // Только задачи с клиентами
        limit: 100,
      ),
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

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return 'Ошибка сети. Проверьте подключение к интернету';
    } else {
      return 'Произошла ошибка';
    }
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

  /// Строит карточку задачи с информацией о клиенте
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/tasks/detail', arguments: task.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о клиенте
              if (task.customer != null) ...[
                Row(
                  children: [
                    Icon(
                      task.customer!.customerType == CustomerType.individual
                          ? Icons.person
                          : Icons.business,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.customer!.displayName ??
                            task.customer!.name ??
                            'Клиент',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ],
              // Заголовок задачи
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _getStatusChip(task.status),
                ],
              ),
              // Описание задачи
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // Метаданные задачи
              Row(
                children: [
                  _getStatusIcon(task.status),
                  const SizedBox(width: 8),
                  if (task.priority != null) ...[
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
                        style: const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (task.isImportant)
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                  if (task.isImportant) const SizedBox(width: 8),
                  if (task.deadline != null) ...[
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
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи по клиентам CRM'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
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
          : _buildTasksView(),
    );
  }

  /// Вид для выбора компании (когда бизнес не выбран)
  Widget _buildBusinessSelectionView(ProfileProvider profileProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Для работы с задачами по клиентам выберите компанию из списка',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Вид со списком задач
  Widget _buildTasksView() {
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
              onPressed: _loadTasks,
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
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Нет задач по клиентам',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Задачи, привязанные к клиентам, будут отображаться здесь',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          return _buildTaskCard(_tasks[index]);
        },
      ),
    );
  }
}
