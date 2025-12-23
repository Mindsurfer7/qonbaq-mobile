import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/business.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../../data/models/task_model.dart';
import '../../core/services/voice_context.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/create_task_form.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/voice_record_widget.dart';

/// Тип фильтра задач
enum TaskFilter {
  myTasks, // Мои задачи
  allTasks, // Все задачи
}

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
  TaskFilter _taskFilter = TaskFilter.myTasks; // По умолчанию "Мои задачи"

  void _showCreateTaskDialog(
    CreateTask createTaskUseCase,
    String businessId,
    UserRepository userRepository, {
    String? initialDescription,
    TaskModel? initialTaskData,
  }) {
    showDialog(
      context: context,
      builder:
          (context) => _CreateTaskDialog(
            businessId: businessId,
            userRepository: userRepository,
            createTaskUseCase: createTaskUseCase,
            initialDescription: initialDescription,
            onSuccess: () {
              // Обновляем список задач после создания
              final profileProvider = Provider.of<ProfileProvider>(
                context,
                listen: false,
              );
              final selectedBusiness = profileProvider.selectedBusiness;
              final getTasksUseCase = Provider.of<GetTasks>(
                context,
                listen: false,
              );
              if (selectedBusiness != null) {
                _loadTasks(getTasksUseCase, selectedBusiness.id);
              }
            },
          ),
    );
  }

  void _showVoiceRecordDialog(
    CreateTask createTaskUseCase,
    String businessId,
    UserRepository userRepository,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Row(
                children: [
                  const Text(
                    'Запись голоса',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Виджет записи голоса
              Expanded(
                child: VoiceRecordWidget(
                  style: VoiceRecordStyle.fullscreen,
                  context: VoiceContext.task,
                  onResultReceived: (result) {
                    // Результат - TaskModel для контекста task
                    final taskData = result as TaskModel;
                    // Закрываем диалог записи
                    Navigator.of(context).pop();
                    // Открываем диалог создания задачи с предзаполненными данными
                    _showCreateTaskDialog(
                      createTaskUseCase,
                      businessId,
                      userRepository,
                      initialTaskData: taskData,
                    );
                  },
                  onError: (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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

    // Получаем информацию о пользователе для определения прав
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;
    
    // Определяем, является ли пользователь админом или директором
    final isAdminOrDirector = currentUser?.isAdmin == true || 
                              profile?.orgStructure.isGeneralDirector == true;
    
    // Определяем, нужно ли передавать assignedTo
    String? assignedTo;
    if (_taskFilter == TaskFilter.myTasks && isAdminOrDirector) {
      // Для админов/директоров при выборе "Мои задачи" передаем ID пользователя
      assignedTo = currentUser?.id;
    } else if (_taskFilter == TaskFilter.allTasks && isAdminOrDirector) {
      // Для админов/директоров при выборе "Все задачи" НЕ передаем assignedTo
      // чтобы бэкенд вернул все задачи компании
      assignedTo = null;
    }
    // Для обычных пользователей не передаем assignedTo
    // (бэкенд сам отфильтрует и вернет только их задачи и задачи, за которыми они наблюдают)

    final result = await getTasksUseCase.call(
      GetTasksParams(
        businessId: businessId,
        assignedTo: assignedTo,
        limit: 50,
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

  @override
  void initState() {
    super.initState();
    // Загружаем задачи после инициализации виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final currentUser = authProvider.user;
      final profile = profileProvider.profile;
      
      // Для директоров и админов по умолчанию показываем "Все задачи"
      final isAdminOrDirector = currentUser?.isAdmin == true || 
                                profile?.orgStructure.isGeneralDirector == true;
      if (isAdminOrDirector) {
        _taskFilter = TaskFilter.allTasks;
      }
      
      final selectedBusiness = profileProvider.selectedBusiness;
      final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
      if (selectedBusiness != null) {
        _loadTasks(getTasksUseCase, selectedBusiness.id);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Проверяем, нужно ли обновить фильтр при загрузке профиля
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;
    final selectedBusiness = profileProvider.selectedBusiness;
    final isAdminOrDirector = currentUser?.isAdmin == true || 
                             profile?.orgStructure.isGeneralDirector == true;
    
    // Если профиль загрузился и пользователь директор, но фильтр еще "Мои задачи",
    // обновляем фильтр на "Все задачи" и перезагружаем задачи
    if (isAdminOrDirector && _taskFilter == TaskFilter.myTasks && selectedBusiness != null && _tasks.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _taskFilter = TaskFilter.allTasks;
          });
          final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
          _loadTasks(getTasksUseCase, selectedBusiness.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context);
    final getTasksUseCase = Provider.of<GetTasks>(context);
    final userRepository = Provider.of<UserRepository>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Фильтр задач (только для админов/директоров)
          if (_canViewAllTasks())
            PopupMenuButton<TaskFilter>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Фильтр задач',
              onSelected: (TaskFilter filter) {
                setState(() {
                  _taskFilter = filter;
                });
                if (selectedBusiness != null) {
                  _loadTasks(getTasksUseCase, selectedBusiness.id);
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<TaskFilter>(
                  value: TaskFilter.myTasks,
                  child: Row(
                    children: [
                      Icon(
                        _taskFilter == TaskFilter.myTasks
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Мои задачи'),
                    ],
                  ),
                ),
                PopupMenuItem<TaskFilter>(
                  value: TaskFilter.allTasks,
                  child: Row(
                    children: [
                      Icon(
                        _taskFilter == TaskFilter.allTasks
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text('Все задачи'),
                    ],
                  ),
                ),
              ],
            ),
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
      body:
          selectedBusiness == null
              ? _buildBusinessSelectionView(profileProvider)
              : _buildTasksView(selectedBusiness, getTasksUseCase),
      floatingActionButton:
          selectedBusiness != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Кнопка микрофона для голосовой записи
                    FloatingActionButton(
                      heroTag: "voice_record",
                      onPressed: () {
                        _showVoiceRecordDialog(
                          createTaskUseCase,
                          selectedBusiness.id,
                          userRepository,
                        );
                      },
                      child: const Icon(Icons.mic),
                    ),
                    const SizedBox(height: 16),
                    // Кнопка плюсика для создания задачи
                    FloatingActionButton(
                      heroTag: "create_task",
                      onPressed: () {
                        _showCreateTaskDialog(
                          createTaskUseCase,
                          selectedBusiness.id,
                          userRepository,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                )
              : null,
    );
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Для работы с задачами выберите компанию из списка',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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

    // Получаем ID текущего пользователя
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isAdminOrDirector = _canViewAllTasks();
    
    // Если админ/директор выбрал "Все задачи", показываем два списка: "Мои задачи" и "Задачи сотрудников"
    final shouldShowAllTasks = isAdminOrDirector && _taskFilter == TaskFilter.allTasks;

    if (_tasks.isEmpty) {
      return Center(
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
      );
    }

    // Разделяем задачи на группы
    final List<Task> myTasks = [];
    final List<Task> employeeTasks = []; // Задачи сотрудников (для директоров)
    final List<Task> observedTasks = []; // Задачи, за которыми наблюдаю (для обычных пользователей)

    for (final task in _tasks) {
      // Проверяем, является ли пользователь исполнителем задачи
      final isMyTask = task.assignedTo == currentUserId;
      
      // Проверяем, является ли пользователь наблюдателем задачи
      final isObserver = currentUserId != null &&
          task.observerIds != null &&
          task.observerIds!.contains(currentUserId);

      if (isMyTask) {
        myTasks.add(task);
      } else if (shouldShowAllTasks) {
        // Для директоров при "Все задачи" - все остальные задачи идут в "Задачи сотрудников"
        // (исключаем задачи без исполнителя и задачи, где пользователь наблюдатель)
        if (task.assignedTo != null && task.assignedTo != currentUserId) {
          employeeTasks.add(task);
        }
      } else if (isObserver) {
        // Для обычных пользователей - задачи, за которыми они наблюдают
        observedTasks.add(task);
      }
    }

    // Проверяем, есть ли задачи для отображения
    final hasTasksToShow = myTasks.isNotEmpty || 
                          (shouldShowAllTasks ? employeeTasks.isNotEmpty : observedTasks.isNotEmpty);

    if (!hasTasksToShow) {
      return Center(
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
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTasks(getTasksUseCase, selectedBusiness.id);
      },
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Секция "Мои задачи"
          if (myTasks.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Мои задачи',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            ...myTasks.map((task) => _buildTaskCard(task)),
          ],

          // Для директоров при "Все задачи" - секция "Задачи сотрудников"
          if (shouldShowAllTasks && employeeTasks.isNotEmpty) ...[
            if (myTasks.isNotEmpty) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.people, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Задачи сотрудников',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ...employeeTasks.map((task) => _buildTaskCard(task)),
          ],

          // Для обычных пользователей - секция "Задачи, за которыми я наблюдаю"
          if (!shouldShowAllTasks && observedTasks.isNotEmpty) ...[
            if (myTasks.isNotEmpty) const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Text(
                    'Задачи, за которыми я наблюдаю',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            ...observedTasks.map((task) => _buildTaskCard(task)),
          ],
        ],
      ),
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

  /// Строит карточку задачи
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            if (task.description != null && task.description!.isNotEmpty)
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
                if (task.priority != null) const SizedBox(width: 8),
                if (task.isImportant)
                  const Icon(Icons.star, size: 16, color: Colors.amber),
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
          Navigator.of(context).pushNamed(
            '/tasks/detail',
            arguments: task.id,
          );
        },
      ),
    );
  }

  /// Проверяет, может ли пользователь видеть все задачи
  bool _canViewAllTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;
    
    // Админы и директоры могут видеть все задачи
    return currentUser?.isAdmin == true || 
           profile?.orgStructure.isGeneralDirector == true;
  }
}

/// Диалог создания задачи с обработкой ошибок
class _CreateTaskDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateTask createTaskUseCase;
  final VoidCallback onSuccess;
  final String? initialDescription;
  final TaskModel? initialTaskData;

  const _CreateTaskDialog({
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
    required this.onSuccess,
    this.initialDescription,
    this.initialTaskData,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                initialDescription: widget.initialDescription,
                initialTaskData: widget.initialTaskData,
                error: _error,
                validationErrors: _validationErrors,
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                },
                onSubmit: (task) async {
                  final result = await widget.createTaskUseCase.call(
                    CreateTaskParams(task: task),
                  );

                  result.fold(
                    (failure) {
                      // Обрабатываем ошибки валидации
                      if (failure is ValidationFailure) {
                        setState(() {
                          _error = failure.serverMessage ?? failure.message;
                          _validationErrors = failure.errors;
                        });
                      } else {
                        setState(() {
                          _error = _getErrorMessage(failure);
                          _validationErrors = null;
                        });
                      }
                    },
                    (createdTask) {
                      // Закрываем диалог и показываем успех
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Задача успешно создана'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        widget.onSuccess();
                      }
                    },
                  );
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
