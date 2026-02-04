import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/update_task.dart';
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
import '../widgets/task_completion_dialog.dart';
import '../widgets/control_point_completion_dialog.dart';
import '../../domain/entities/control_point.dart';
import '../../domain/usecases/get_control_points.dart';

/// Тип фильтра задач
enum TaskFilter {
  myTasks, // Мои задачи
  allTasks, // Все задачи
}

/// Тип списка задач
enum TaskListType {
  current, // Текущие задачи (pending, in_progress)
  completed, // Выполненные задачи
}

/// Страница задач
///
/// @deprecated Используйте [OperationalTasksPage] вместо этого класса.
/// Этот класс устарел и будет удален в будущих версиях.
/// Правильный роут: /business/operational/tasks
@Deprecated(
  'Используйте OperationalTasksPage по роуту /business/operational/tasks',
)
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> with TickerProviderStateMixin {
  bool _isLoadingTasks = false;
  String? _error;
  List<Task> _tasks = [];
  TaskFilter _taskFilter = TaskFilter.myTasks; // По умолчанию "Мои задачи"
  late TabController _tabController;
  TaskListType _currentListType = TaskListType.current;

  // Для точек контроля
  bool _isLoadingControlPoints = false;
  List<ControlPoint> _controlPoints = [];

  // Для анимации выполнения задач
  String? _animatingTaskId;
  AnimationController? _slideAnimationController;
  Animation<Offset>? _slideAnimation;

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
      builder:
          (context) => Dialog(
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
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Определяем, является ли пользователь админом или директором
    final isAdminOrDirector =
        currentUser?.isAdmin == true ||
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

    // Определяем фильтр по статусу в зависимости от текущего списка
    TaskStatus? statusFilter;
    if (_currentListType == TaskListType.completed) {
      // Для выполненных задач - только completed
      statusFilter = TaskStatus.completed;
    }
    // Для текущих задач фильтр не применяем (показываем pending и in_progress)

    final result = await getTasksUseCase.call(
      GetTasksParams(
        businessId: businessId,
        assignedTo: assignedTo,
        status: statusFilter,
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
        // Загружаем точки контроля после загрузки задач
        if (businessId != null) {
          _loadControlPoints(businessId);
        }
      },
    );
  }

  Future<void> _loadControlPoints(String businessId) async {
    if (_isLoadingControlPoints) {
      print('TasksPage: _loadControlPoints already loading, skipping');
      return;
    }

    print('TasksPage: _loadControlPoints called with businessId: $businessId');

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Проверяем, является ли пользователь гендиректором
    final isGeneralDirector =
        currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true;

    print('TasksPage: isGeneralDirector: $isGeneralDirector');
    print('TasksPage: currentUser?.id: ${currentUser?.id}');

    setState(() {
      _isLoadingControlPoints = true;
    });

    final getControlPointsUseCase = Provider.of<GetControlPoints>(
      context,
      listen: false,
    );

    print('TasksPage: Calling useCase with params:');
    print('  businessId: $businessId');
    print('  showAll: ${isGeneralDirector ? true : null}');
    print('  assignedTo: ${isGeneralDirector ? null : currentUser?.id}');
    print('  isActive: true');

    final result = await getControlPointsUseCase.call(
      GetControlPointsParams(
        businessId: businessId,
        // Для гендиректора передаем showAll=true, чтобы получить все точки контроля бизнеса
        showAll: isGeneralDirector ? true : null,
        // Для обычных пользователей показываем только их точки контроля
        assignedTo: isGeneralDirector ? null : currentUser?.id,
        isActive: true, // Показываем только активные точки контроля
        page: 1,
        limit: 50, // Загружаем достаточно для отображения
      ),
    );

    result.fold(
      (failure) {
        print('TasksPage: UseCase returned Left (failure): ${failure.message}');
        setState(() {
          _isLoadingControlPoints = false;
          // Ошибки точек контроля не критичны, просто не показываем их
        });
      },
      (paginatedResult) {
        print(
          'TasksPage: UseCase returned Right (success): ${paginatedResult.items.length} items',
        );
        setState(() {
          _isLoadingControlPoints = false;
          _controlPoints = paginatedResult.items;
        });
        print(
          'TasksPage: ControlPoints in state: ${_controlPoints.length} items',
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Инициализация анимации
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0), // Движение направо
    ).animate(
      CurvedAnimation(
        parent: _slideAnimationController!,
        curve: Curves.easeInOut,
      ),
    );

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
      final isAdminOrDirector =
          currentUser?.isAdmin == true ||
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

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentListType =
            _tabController.index == 0
                ? TaskListType.current
                : TaskListType.completed;
      });
      // Перезагрузить задачи при переключении
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _slideAnimationController?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Проверяем, нужно ли обновить фильтр при загрузке профиля
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;
    final selectedBusiness = profileProvider.selectedBusiness;
    final isAdminOrDirector =
        currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true;

    // Если профиль загрузился и пользователь директор, но фильтр еще "Мои задачи",
    // обновляем фильтр на "Все задачи" и перезагружаем задачи
    if (isAdminOrDirector &&
        _taskFilter == TaskFilter.myTasks &&
        selectedBusiness != null &&
        _tasks.isNotEmpty) {
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Текущие'), Tab(text: 'Выполненные')],
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
              itemBuilder:
                  (BuildContext context) => [
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
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildTasksView(
                    selectedBusiness,
                    getTasksUseCase,
                    TaskListType.current,
                  ),
                  _buildTasksView(
                    selectedBusiness,
                    getTasksUseCase,
                    TaskListType.completed,
                  ),
                ],
              ),
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
  Widget _buildTasksView(
    Business selectedBusiness,
    GetTasks getTasksUseCase,
    TaskListType listType,
  ) {
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
    final shouldShowAllTasks =
        isAdminOrDirector && _taskFilter == TaskFilter.allTasks;

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

    // Разделяем задачи на группы в зависимости от типа списка
    final List<Task> myTasks = [];
    final List<Task> employeeTasks = []; // Задачи сотрудников (для директоров)
    final List<Task> observedTasks =
        []; // Задачи, за которыми наблюдаю (для обычных пользователей)

    for (final task in _tasks) {
      // Для выполненных задач показываем все задачи со статусом completed
      if (listType == TaskListType.completed) {
        // Проверяем, является ли пользователь исполнителем задачи
        final isMyTask = task.assignedTo == currentUserId;

        if (isMyTask) {
          myTasks.add(task);
        } else if (shouldShowAllTasks) {
          // Для директоров при "Все задачи" - все остальные выполненные задачи
          if (task.assignedTo != null && task.assignedTo != currentUserId) {
            employeeTasks.add(task);
          }
        }
        continue;
      }

      // Для текущих задач фильтруем по статусу (только pending и in_progress)
      if (task.status == TaskStatus.completed ||
          task.status == TaskStatus.cancelled) {
        continue; // Пропускаем выполненные и отмененные задачи для вкладки "Текущие"
      }

      // Проверяем, является ли пользователь исполнителем задачи
      final isMyTask = task.assignedTo == currentUserId;

      // Проверяем, является ли пользователь наблюдателем задачи
      final isObserver =
          currentUserId != null &&
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
    final hasTasksToShow =
        myTasks.isNotEmpty ||
        (shouldShowAllTasks
            ? employeeTasks.isNotEmpty
            : observedTasks.isNotEmpty);

    // Проверяем, есть ли контрольные точки для отображения (только для текущих задач)
    final hasControlPointsToShow =
        listType == TaskListType.current && _controlPoints.isNotEmpty;

    // Если нет ни задач, ни контрольных точек, показываем пустой экран
    if (!hasTasksToShow && !hasControlPointsToShow) {
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
        await _loadControlPoints(selectedBusiness.id);
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
                  Text(
                    listType == TaskListType.completed
                        ? 'Мои выполненные'
                        : 'Мои задачи',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            ...myTasks.map((task) => _buildTaskCard(task, listType)),
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
                  Text(
                    listType == TaskListType.completed
                        ? 'Выполненные сотрудниками'
                        : 'Задачи сотрудников',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ...employeeTasks.map((task) => _buildTaskCard(task, listType)),
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
            ...observedTasks.map((task) => _buildTaskCard(task, listType)),
          ],

          // Секция "Точки контроля" (только для текущих задач)
          if (listType == TaskListType.current &&
              _controlPoints.isNotEmpty) ...[
            // Отладочная информация
            Builder(
              builder: (context) {
                print('TasksPage: Building UI for current tasks');
                print(
                  'TasksPage: _controlPoints.length: ${_controlPoints.length}',
                );
                print(
                  'TasksPage: _controlPoints.isNotEmpty: ${_controlPoints.isNotEmpty}',
                );
                return const SizedBox.shrink();
              },
            ),
            if (myTasks.isNotEmpty ||
                (shouldShowAllTasks && employeeTasks.isNotEmpty) ||
                (!shouldShowAllTasks && observedTasks.isNotEmpty))
              const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.assessment, size: 20, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'Точки контроля',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            ..._controlPoints.map(
              (controlPoint) => _buildControlPointCard(controlPoint),
            ),
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
  Widget _buildTaskCard(Task task, TaskListType listType) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    final isMyTask = task.assignedTo == currentUserId;
    final isCompleted = task.status == TaskStatus.completed;
    final canComplete =
        isMyTask &&
        task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled &&
        listType == TaskListType.current; // Чекбокс только для текущих задач
    final showCheckbox =
        isMyTask &&
        task.status != TaskStatus.cancelled &&
        listType == TaskListType.current;

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCheckbox)
              Checkbox(
                value: isCompleted,
                onChanged:
                    canComplete
                        ? (value) {
                          if (value == true) {
                            _completeTask(task);
                          }
                        }
                        : null,
              )
            else
              _getStatusIcon(task.status),
          ],
        ),
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
                      style: const TextStyle(fontSize: 10, color: Colors.white),
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
          Navigator.of(context).pushNamed('/tasks/detail', arguments: task.id);
        },
      ),
    );

    // Применяем анимацию если задача анимируется
    if (_animatingTaskId == task.id && _slideAnimation != null) {
      return SlideTransition(position: _slideAnimation!, child: card);
    }

    return card;
  }

  String _getFrequencyText(RecurrenceFrequency frequency) {
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

  /// Строит карточку точки контроля
  Widget _buildControlPointCard(ControlPoint controlPoint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.assessment,
          color: controlPoint.isActive ? Colors.purple : Colors.grey,
        ),
        title: Text(
          controlPoint.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: controlPoint.isActive ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controlPoint.description != null &&
                controlPoint.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  controlPoint.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_getFrequencyText(controlPoint.frequency)} (каждые ${controlPoint.interval})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (controlPoint.assignee != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getUserDisplayName(controlPoint.assignee!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            if (controlPoint.metrics != null &&
                controlPoint.metrics!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Метрик: ${controlPoint.metrics!.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controlPoint.isActive)
              Icon(Icons.check_circle, color: Colors.green, size: 20)
            else
              Icon(Icons.cancel, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          // TODO: Переход на детальную страницу точки контроля
          // Пока можно показать snackbar или открыть диалог
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Точка контроля: ${controlPoint.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Отмечает задачу как выполненную с анимацией
  Future<void> _completeTask(Task task) async {
    Map<String, dynamic>? completionResult;

    // Проверяем тип задачи и показываем соответствующий диалог
    if (task.hasControlPoint &&
        task.indicators != null &&
        task.indicators!.isNotEmpty) {
      // Для точки контроля показываем диалог с метриками
      completionResult = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => ControlPointCompletionDialog(
              taskTitle: task.title,
              indicators: task.indicators!,
            ),
      );
    } else {
      // Для обычной задачи или регулярной задачи показываем диалог с resultText и файлом
      completionResult = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (context) => TaskCompletionDialog(taskTitle: task.title),
      );
    }

    // Если пользователь отменил диалог, ничего не делаем
    if (completionResult == null) {
      return;
    }

    // Извлекаем данные в зависимости от типа задачи
    String? resultText;
    String? resultFileId;
    List<TaskIndicator>? updatedIndicators;

    if (task.hasControlPoint &&
        task.indicators != null &&
        task.indicators!.isNotEmpty) {
      // Для точки контроля получаем обновленные метрики
      updatedIndicators = completionResult['indicators'] as List<TaskIndicator>;
    } else {
      // Для обычной задачи получаем resultText и resultFileId
      resultText = completionResult['resultText'] as String?;
      resultFileId = completionResult['resultFileId'] as String?;
    }

    final updateTaskUseCase = Provider.of<UpdateTask>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);

    // Начинаем анимацию
    setState(() {
      _animatingTaskId = task.id;
    });

    // Запускаем анимацию ухода направо
    await _slideAnimationController!.forward();

    // Создаем обновленную задачу со статусом completed
    final updatedTask = Task(
      id: task.id,
      businessId: task.businessId,
      title: task.title,
      description: task.description,
      status: TaskStatus.completed,
      priority: task.priority,
      assignedTo: task.assignedTo,
      assignedBy: task.assignedBy,
      assignmentDate: task.assignmentDate,
      deadline: task.deadline,
      isImportant: task.isImportant,
      isRecurring: task.isRecurring,
      hasControlPoint: task.hasControlPoint,
      dontForget: task.dontForget,
      voiceNoteUrl: task.voiceNoteUrl,
      // Для точки контроля resultText и resultFileId должны быть null
      // Для обычной задачи - заполняются из диалога
      resultText: resultText,
      resultFileId: resultFileId,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
      observerIds: task.observerIds,
      attachments: task.attachments,
      // Для точки контроля используем обновленные метрики с actualValue
      // Для обычной задачи - оставляем исходные метрики
      indicators: updatedIndicators ?? task.indicators,
      recurrence: task.recurrence,
      business: task.business,
      assignee: task.assignee,
      assigner: task.assigner,
      observers: task.observers,
      comments: task.comments,
    );

    final result = await updateTaskUseCase.call(
      UpdateTaskParams(id: task.id, task: updatedTask),
    );

    result.fold(
      (failure) {
        // При ошибке возвращаем анимацию обратно
        _slideAnimationController!.reverse();
        setState(() {
          _animatingTaskId = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (updatedTask) async {
        // Успешно выполнено - завершаем анимацию и переключаемся на вкладку "Выполненные"
        setState(() {
          _animatingTaskId = null;
        });

        // Сбрасываем анимацию для следующего использования
        _slideAnimationController!.reset();

        // Переключаемся на вкладку "Выполненные"
        if (_currentListType == TaskListType.current) {
          _tabController.animateTo(1);
        }

        // Обновляем список задач после успешного обновления
        if (selectedBusiness != null) {
          _loadTasks(getTasksUseCase, selectedBusiness.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Задача выполнена!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  /// Проверяет, может ли пользователь видеть все задачи
  bool _canViewAllTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
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
                onSubmit: (taskModel) async {
                  final result = await widget.createTaskUseCase.call(
                    CreateTaskParams(task: taskModel),
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
