import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/control_point.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/get_control_points.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../../data/models/task_model.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/create_task_form.dart';
import '../widgets/voice_task_dialog.dart';
import '../widgets/task_skeleton.dart';

/// Страница задач операционного блока с 4 блоками
class OperationalTasksPage extends StatefulWidget {
  const OperationalTasksPage({super.key});

  @override
  State<OperationalTasksPage> createState() => _OperationalTasksPageState();
}

class _OperationalTasksPageState extends State<OperationalTasksPage> {
  String? _error;

  // Флаги загрузки для каждой категории
  bool _isLoadingTodayRecurring = false;
  bool _isLoadingTodayIrregular = false;
  bool _isLoadingWeekRecurring = false;
  bool _isLoadingWeekIrregular = false;
  bool _isLoadingControlPointTasks = false;
  bool _isLoadingControlPoints = false;

  // Данные для блоков
  List<Task> _todayRecurringTasks = [];
  List<Task> _todayIrregularTasks = [];
  List<Task> _weekRecurringTasks = [];
  List<Task> _weekIrregularTasks = [];
  List<Task> _controlPointTasks = [];
  List<ControlPoint> _controlPoints = []; // Истинные точки контроля

  // Фильтр для гендиректора/начальника департамента
  bool _showAll = false;

  // Свитчер для блока точек контроля: true = Контроль, false = Задачи
  bool _showControlPointManagement = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllTasks();
    });
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

    // Гендиректор или начальник департамента
    return currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true ||
        profile?.orgStructure.isDepartmentHead == true;
  }

  /// Получает начало недели (понедельник)
  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Получает конец недели (воскресенье)
  DateTime _getEndOfWeek(DateTime date) {
    final startOfWeek = _getStartOfWeek(date);
    return startOfWeek.add(const Duration(days: 6));
  }

  /// Загружает все задачи для всех блоков
  Future<void> _loadAllTasks() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return;
    }

    setState(() {
      _error = null;
      // Устанавливаем флаги загрузки для всех категорий
      _isLoadingTodayRecurring = true;
      _isLoadingTodayIrregular = true;
      _isLoadingWeekRecurring = true;
      _isLoadingWeekIrregular = true;
      _isLoadingControlPointTasks = true;
      _isLoadingControlPoints = true;
    });

    final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Определяем параметры для запросов
    final isAdminOrDirector =
        currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true ||
        profile?.orgStructure.isDepartmentHead == true;

    final showAll = isAdminOrDirector && _showAll;
    final assignedTo =
        (isAdminOrDirector && !_showAll) ? currentUser?.id : null;

    // Получаем сегодняшнюю дату
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Получаем завтрашнюю дату (для задач на неделе, чтобы не дублировать с сегодняшними)
    final tomorrow = todayDate.add(const Duration(days: 1));
    final tomorrowDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    // Получаем конец недели для диапазона задач на неделе
    final endOfWeek = _getEndOfWeek(todayDate);
    final endOfWeekDate = DateTime(
      endOfWeek.year,
      endOfWeek.month,
      endOfWeek.day,
    );

    // Загружаем все задачи параллельно
    try {
      final futures = <Future<void>>[
        // 1. Регулярные задачи на сегодня
        _loadTodayRecurringTasks(
          getTasksUseCase,
          selectedBusiness.id,
          assignedTo,
          showAll,
          todayDate,
        ),
        // 2. Нерегулярные задачи на сегодня
        _loadTodayIrregularTasks(
          getTasksUseCase,
          selectedBusiness.id,
          assignedTo,
          showAll,
        ),
        // 3. Регулярные задачи на неделе
        _loadWeekRecurringTasks(
          getTasksUseCase,
          selectedBusiness.id,
          assignedTo,
          showAll,
          tomorrowDate,
        ),
        // 4. Нерегулярные задачи на неделе
        _loadWeekIrregularTasks(
          getTasksUseCase,
          selectedBusiness.id,
          assignedTo,
          showAll,
          tomorrowDate,
          endOfWeekDate,
        ),
        // 5. Точки контроля (задачи из точек контроля)
        _loadControlPointTasks(
          getTasksUseCase,
          selectedBusiness.id,
          assignedTo,
          showAll,
        ),
      ];

      // 6. Истинные точки контроля (только для гендиректора/начальника департамента)
      if (isAdminOrDirector) {
        futures.add(
          _loadControlPoints(selectedBusiness.id, showAll, currentUser?.id),
        );
      } else {
        // Для обычных пользователей сразу сбрасываем флаг загрузки
        setState(() {
          _isLoadingControlPoints = false;
          _controlPoints = [];
        });
      }

      await Future.wait(futures);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ошибка при загрузке задач: $e';
        });
      }
    }
  }

  /// Загружает регулярные задачи на сегодня
  Future<void> _loadTodayRecurringTasks(
    GetTasks getTasksUseCase,
    String businessId,
    String? assignedTo,
    bool showAll,
    DateTime todayDate,
  ) async {
    try {
      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: businessId,
          assignedTo: assignedTo,
          hasRecurringTask: true,
          scheduledDate: todayDate,
          showAll: showAll,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingTodayRecurring = false;
            if (_error == null) {
              _error = _getErrorMessage(failure);
            }
          });
        },
        (tasks) {
          setState(() {
            _isLoadingTodayRecurring = false;
            _todayRecurringTasks = tasks;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTodayRecurring = false;
        });
      }
    }
  }

  /// Загружает нерегулярные задачи на сегодня
  Future<void> _loadTodayIrregularTasks(
    GetTasks getTasksUseCase,
    String businessId,
    String? assignedTo,
    bool showAll,
  ) async {
    try {
      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: businessId,
          assignedTo: assignedTo,
          hasRecurringTask: false,
          hasControlPoint: false,
          deadlineToday: true,
          showAll: showAll,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingTodayIrregular = false;
            if (_error == null) {
              _error = _getErrorMessage(failure);
            }
          });
        },
        (tasks) {
          setState(() {
            _isLoadingTodayIrregular = false;
            _todayIrregularTasks = tasks;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTodayIrregular = false;
        });
      }
    }
  }

  /// Загружает регулярные задачи на неделе
  Future<void> _loadWeekRecurringTasks(
    GetTasks getTasksUseCase,
    String businessId,
    String? assignedTo,
    bool showAll,
    DateTime tomorrowDate,
  ) async {
    try {
      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: businessId,
          assignedTo: assignedTo,
          hasRecurringTask: true,
          scheduledDate: tomorrowDate,
          showAll: showAll,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingWeekRecurring = false;
            if (_error == null) {
              _error = _getErrorMessage(failure);
            }
          });
        },
        (tasks) {
          setState(() {
            _isLoadingWeekRecurring = false;
            _weekRecurringTasks = tasks;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeekRecurring = false;
        });
      }
    }
  }

  /// Загружает нерегулярные задачи на неделе
  Future<void> _loadWeekIrregularTasks(
    GetTasks getTasksUseCase,
    String businessId,
    String? assignedTo,
    bool showAll,
    DateTime tomorrowDate,
    DateTime endOfWeekDate,
  ) async {
    try {
      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: businessId,
          assignedTo: assignedTo,
          hasRecurringTask: false,
          hasControlPoint: false,
          deadlineFrom: tomorrowDate,
          deadlineTo: endOfWeekDate,
          showAll: showAll,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingWeekIrregular = false;
            if (_error == null) {
              _error = _getErrorMessage(failure);
            }
          });
        },
        (tasks) {
          setState(() {
            _isLoadingWeekIrregular = false;
            _weekIrregularTasks = tasks;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWeekIrregular = false;
        });
      }
    }
  }

  /// Загружает задачи из точек контроля
  Future<void> _loadControlPointTasks(
    GetTasks getTasksUseCase,
    String businessId,
    String? assignedTo,
    bool showAll,
  ) async {
    try {
      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: businessId,
          assignedTo: assignedTo,
          hasControlPoint: true,
          showAll: showAll,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoadingControlPointTasks = false;
            if (_error == null) {
              _error = _getErrorMessage(failure);
            }
          });
        },
        (tasks) {
          setState(() {
            _isLoadingControlPointTasks = false;
            _controlPointTasks = tasks;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingControlPointTasks = false;
        });
      }
    }
  }

  /// Загружает истинные точки контроля
  Future<void> _loadControlPoints(
    String businessId,
    bool showAll,
    String? userId,
  ) async {
    try {
      final getControlPointsUseCase = Provider.of<GetControlPoints>(
        context,
        listen: false,
      );
      final result = await getControlPointsUseCase.call(
        GetControlPointsParams(
          businessId: businessId,
          assignedTo: showAll ? null : userId,
          isActive: true,
          showAll: showAll,
          page: 1,
          limit: 100,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          // Ошибки не критичны, очищаем список
          setState(() {
            _isLoadingControlPoints = false;
            _controlPoints = [];
          });
        },
        (paginatedResult) {
          setState(() {
            _isLoadingControlPoints = false;
            _controlPoints = paginatedResult.items;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingControlPoints = false;
          _controlPoints = [];
        });
      }
    }
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;
    final canViewAll = _canViewAllTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Иконка обновления (стилизованная)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Material(
              color: context.appTheme.accentPrimary,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _loadAllTasks,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.refresh,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Свитчер с текстом внутри для гендиректора/начальника департамента
          if (canViewAll)
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAll = !_showAll;
                });
                _loadAllTasks();
              },
              child: Container(
                width: 80,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color:
                      _showAll
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Stack(
                  children: [
                    // Текст "Все" слева (когда включен)
                    if (_showAll)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'Все',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    // Текст "Мои" справа (когда выключен)
                    if (!_showAll)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Text(
                            'Мои',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    // Переключатель (справа когда включен, слева когда выключен)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      left: _showAll ? 48 : 2,
                      right: _showAll ? 2 : 48,
                      top: 2,
                      bottom: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Иконка плюсика (стилизованная)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Material(
              color: context.appTheme.accentPrimary,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  _showCreateTaskDialog();
                },
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: const Icon(Icons.add, size: 20, color: Colors.black),
                ),
              ),
            ),
          ),
          // Иконка микрофона (стилизованная, вместо домика)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Material(
              color:
                  selectedBusiness != null
                      ? context.appTheme.accentPrimary
                      : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap:
                    selectedBusiness != null
                        ? () {
                          _showVoiceTaskDialog(selectedBusiness.id);
                        }
                        : null,
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.mic,
                    size: 20,
                    color:
                        selectedBusiness != null
                            ? Colors.black
                            : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          selectedBusiness == null
              ? _buildBusinessSelectionView(profileProvider)
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAllTasks,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : _buildTasksGrid(),
    );
  }

  /// Вид для выбора компании
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
                  'Для работы с задачами выберите компанию из списка',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const BusinessSelectorWidget(compact: false),
        ],
      ),
    );
  }

  /// Сетка с 4 блоками задач
  Widget _buildTasksGrid() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Верхний ряд: 50% высоты экрана
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildTodayTasksBlock(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildWeekTasksBlock(),
                  ),
                ),
              ],
            ),
          ),
          // Нижний ряд: 50% высоты экрана
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildControlPointsBlock(),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _buildAnalyticsBlock(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Блок задач на сегодня (разделен горизонтально на регулярные и нерегулярные)
  Widget _buildTodayTasksBlock() {
    return Card(
      color: Colors.green.shade50,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Задачи на сегодня',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Разделение на две части горизонтально (в ряд)
                Expanded(
                  child: Column(
                    children: [
                      // Верхняя половина: Регулярные задачи
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Регулярные',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child:
                                    _isLoadingTodayRecurring
                                        ? const TaskSkeleton(count: 3)
                                        : _todayRecurringTasks.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'Нет задач',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                        : SingleChildScrollView(
                                          child: Column(
                                            children:
                                                _todayRecurringTasks.map((
                                                  task,
                                                ) {
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    child: _buildTaskItem(task),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Нижняя половина: Нерегулярные задачи
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.black),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Нерегулярные',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child:
                                    _isLoadingTodayIrregular
                                        ? const TaskSkeleton(count: 3)
                                        : _todayIrregularTasks.isEmpty
                                        ? const Center(
                                          child: Text(
                                            'Нет задач',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        )
                                        : SingleChildScrollView(
                                          child: Column(
                                            children:
                                                _todayIrregularTasks.map((
                                                  task,
                                                ) {
                                                  return Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    child: _buildTaskItem(task),
                                                  );
                                                }).toList(),
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Маленький плюсик в верхнем правом углу
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _showCreateTaskDialog(),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Блок задач на неделе (регулярные + нерегулярные)
  Widget _buildWeekTasksBlock() {
    // Объединяем регулярные и нерегулярные задачи на неделе
    final allWeekTasks = [..._weekRecurringTasks, ..._weekIrregularTasks];

    return Card(
      color: Colors.blue.shade50,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Задачи на неделе',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Список всех задач на неделе
                Expanded(
                  child:
                      _isLoadingWeekRecurring || _isLoadingWeekIrregular
                          ? const TaskSkeleton(count: 5)
                          : allWeekTasks.isEmpty
                          ? const Center(
                            child: Text(
                              'Нет задач',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                          : SingleChildScrollView(
                            child: Column(
                              children:
                                  allWeekTasks
                                      .map((task) => _buildTaskItem(task))
                                      .toList(),
                            ),
                          ),
                ),
              ],
            ),
          ),
          // Маленький плюсик в верхнем правом углу
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => _showCreateTaskDialog(),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Блок точек контроля со свитчером "Контроль | Задачи"
  Widget _buildControlPointsBlock() {
    final canViewControlPoints = _canViewAllTasks();

    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок блока
            const Text(
              'Точки Контроля',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // Свитчер "Контроль | Задачи" (только для гендиректора/управленца)
            if (canViewControlPoints)
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showControlPointManagement = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _showControlPointManagement
                                  ? Colors.purple.shade200
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: const Text(
                          'Контроль',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showControlPointManagement = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              !_showControlPointManagement
                                  ? Colors.purple.shade200
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey, width: 1),
                        ),
                        child: const Text(
                          'Задачи',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Контент в зависимости от выбранного режима
            Expanded(
              child:
                  canViewControlPoints && _showControlPointManagement
                      ? _isLoadingControlPoints
                          ? const TaskSkeleton(count: 5)
                          : _controlPoints.isEmpty
                          ? const Center(
                            child: Text(
                              'Нет точек контроля',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          )
                          : SingleChildScrollView(
                            child: Column(
                              children:
                                  _controlPoints.asMap().entries.map((entry) {
                                    return _buildControlPointEntityItem(
                                      entry.value,
                                      entry.key + 1,
                                    );
                                  }).toList(),
                            ),
                          )
                      : _isLoadingControlPointTasks
                      ? const TaskSkeleton(count: 5)
                      : _controlPointTasks.isEmpty
                      ? const Center(
                        child: Text(
                          'Нет задач',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      )
                      : SingleChildScrollView(
                        child: Column(
                          children:
                              _controlPointTasks.asMap().entries.map((entry) {
                                return _buildControlPointItem(
                                  entry.value,
                                  entry.key + 1,
                                );
                              }).toList(),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  /// Блок аналитики со ссылками
  Widget _buildAnalyticsBlock() {
    return Card(
      color: Colors.yellow.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Аналитика',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildAnalyticsLink(
                      'Задачи: этот месяц',
                      '/tasks/analytics/month',
                    ),
                    _buildAnalyticsLink(
                      'Не сделаны',
                      '/tasks/analytics/not-completed',
                    ),
                    _buildAnalyticsLink(
                      'Задачи: просрок',
                      '/tasks/analytics/overdue',
                    ),
                    _buildAnalyticsLink(
                      'ТК в этом месяце',
                      '/tasks/analytics/control-points-month',
                    ),
                    _buildAnalyticsLink(
                      'ТК сделаны',
                      '/tasks/analytics/control-points-completed',
                    ),
                    _buildAnalyticsLink(
                      'ТК не сделаны',
                      '/tasks/analytics/control-points-not-completed',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ссылка в блоке аналитики
  Widget _buildAnalyticsLink(String title, String route) {
    return InkWell(
      onTap: () {
        // TODO: Реализовать навигацию на страницы аналитики
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Переход на: $title'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics, size: 14, color: Colors.yellow.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }

  /// Элемент задачи в списке (маленькая строка)
  Widget _buildTaskItem(Task task) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/tasks/detail', arguments: task.id);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        constraints: const BoxConstraints(minWidth: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          task.title,
          style: TextStyle(
            fontSize: 11,
            decoration:
                task.status == TaskStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
            color:
                task.status == TaskStatus.completed
                    ? Colors.grey
                    : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Элемент точки контроля в списке (маленькая строка)
  Widget _buildControlPointItem(Task task, int index) {
    final frequencyText = _getFrequencyText(task);
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/tasks/detail', arguments: task.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          '$index. ${task.title} $frequencyText',
          style: TextStyle(
            fontSize: 10,
            decoration:
                task.status == TaskStatus.completed
                    ? TextDecoration.lineThrough
                    : null,
            color:
                task.status == TaskStatus.completed
                    ? Colors.grey
                    : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Элемент истинной точки контроля в списке (маленькая строка)
  Widget _buildControlPointEntityItem(ControlPoint controlPoint, int index) {
    final frequencyText = _getControlPointFrequencyText(controlPoint);
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).pushNamed('/control-points/detail', arguments: controlPoint.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          '$index. ${controlPoint.title} $frequencyText',
          style: TextStyle(
            fontSize: 10,
            color: controlPoint.isActive ? Colors.black87 : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Получает текст частоты для точки контроля
  String _getFrequencyText(Task task) {
    if (task.recurrence == null) return '';
    switch (task.recurrence!.frequency) {
      case RecurrenceFrequency.daily:
        return 'ежедневные';
      case RecurrenceFrequency.weekly:
        return 'еженедельные';
      case RecurrenceFrequency.monthly:
        return 'ежемесячные';
      case RecurrenceFrequency.yearly:
        return 'ежегодные';
    }
  }

  /// Получает текст частоты для истинной точки контроля
  String _getControlPointFrequencyText(ControlPoint controlPoint) {
    switch (controlPoint.frequency) {
      case RecurrenceFrequency.daily:
        return 'ежедневные';
      case RecurrenceFrequency.weekly:
        return 'еженедельные';
      case RecurrenceFrequency.monthly:
        return 'ежемесячные';
      case RecurrenceFrequency.yearly:
        return 'ежегодные';
    }
  }

  /// Показывает диалог голосового создания задачи
  void _showVoiceTaskDialog(String businessId) {
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    showDialog(
      context: context,
      builder:
          (context) => VoiceTaskDialog(
            businessId: businessId,
            userRepository: userRepository,
            createTaskUseCase: createTaskUseCase,
          ),
    ).then((_) {
      // Обновляем список задач после закрытия диалога
      _loadAllTasks();
    });
  }

  /// Показывает диалог создания задачи
  void _showCreateTaskDialog({TaskModel? initialTaskData}) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) {
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _CreateTaskDialog(
            businessId: selectedBusiness.id,
            userRepository: userRepository,
            createTaskUseCase: createTaskUseCase,
            initialTaskData: initialTaskData,
            onSuccess: () {
              _loadAllTasks();
            },
          ),
    );
  }
}

/// Диалог создания задачи с обработкой ошибок
class _CreateTaskDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateTask createTaskUseCase;
  final VoidCallback onSuccess;
  final TaskModel? initialTaskData;

  const _CreateTaskDialog({
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
    required this.onSuccess,
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
