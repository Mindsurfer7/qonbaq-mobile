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
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/create_task_form.dart';

/// Страница задач операционного блока с 4 блоками
class OperationalTasksPage extends StatefulWidget {
  const OperationalTasksPage({super.key});

  @override
  State<OperationalTasksPage> createState() => _OperationalTasksPageState();
}

class _OperationalTasksPageState extends State<OperationalTasksPage> {
  bool _isLoading = false;
  String? _error;
  
  // Данные для блоков
  List<Task> _recurringTasks = [];
  List<Task> _irregularTasks = [];
  List<Task> _importantTasks = [];
  List<Task> _controlPointTasks = [];
  List<ControlPoint> _controlPoints = []; // Истинные точки контроля
  
  // Фильтр для гендиректора/начальника департамента
  bool _showAll = false;

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
      _isLoading = true;
      _error = null;
    });

    final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Определяем параметры для запросов
    final isAdminOrDirector = currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true ||
        profile?.orgStructure.isDepartmentHead == true;
    
    final showAll = isAdminOrDirector && _showAll;
    final assignedTo = (isAdminOrDirector && !_showAll) ? currentUser?.id : null;
    
    // Получаем сегодняшнюю дату
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    try {
      // 1. Регулярные задачи на сегодня
      final recurringResult = await getTasksUseCase.call(
        GetTasksParams(
          businessId: selectedBusiness.id,
          assignedTo: assignedTo,
          hasRecurringTask: true,
          scheduledDate: todayDate,
          showAll: showAll,
          limit: 100,
        ),
      );

      // 2. Нерегулярные задачи на сегодня
      final irregularResult = await getTasksUseCase.call(
        GetTasksParams(
          businessId: selectedBusiness.id,
          assignedTo: assignedTo,
          hasRecurringTask: false,
          hasControlPoint: false,
          deadlineToday: true,
          showAll: showAll,
          limit: 100,
        ),
      );

      // 3. Важные задачи
      final importantResult = await getTasksUseCase.call(
        GetTasksParams(
          businessId: selectedBusiness.id,
          assignedTo: assignedTo,
          isImportant: true,
          showAll: showAll,
          limit: 100,
        ),
      );

      // 4. Точки контроля (задачи из точек контроля)
      final controlPointResult = await getTasksUseCase.call(
        GetTasksParams(
          businessId: selectedBusiness.id,
          assignedTo: assignedTo,
          hasControlPoint: true,
          showAll: showAll,
          limit: 100,
        ),
      );

      // 5. Истинные точки контроля (только для гендиректора/начальника департамента)
      if (isAdminOrDirector) {
        final getControlPointsUseCase = Provider.of<GetControlPoints>(
          context,
          listen: false,
        );
        final controlPointsResult = await getControlPointsUseCase.call(
          GetControlPointsParams(
            businessId: selectedBusiness.id,
            assignedTo: showAll ? null : currentUser?.id,
            isActive: true,
            showAll: showAll,
            page: 1,
            limit: 100,
          ),
        );

        controlPointsResult.fold(
          (failure) {
            // Ошибки не критичны, очищаем список
            setState(() {
              _controlPoints = [];
            });
          },
          (paginatedResult) {
            setState(() {
              _controlPoints = paginatedResult.items;
            });
          },
        );
      } else {
        // Для обычных пользователей очищаем список точек контроля
        setState(() {
          _controlPoints = [];
        });
      }

      // Обрабатываем результаты
      recurringResult.fold(
        (failure) {
          setState(() {
            _error = _getErrorMessage(failure);
          });
        },
        (tasks) {
          setState(() {
            _recurringTasks = tasks;
          });
        },
      );

      irregularResult.fold(
        (failure) {
          if (_error == null) {
            setState(() {
              _error = _getErrorMessage(failure);
            });
          }
        },
        (tasks) {
          setState(() {
            _irregularTasks = tasks;
          });
        },
      );

      importantResult.fold(
        (failure) {
          if (_error == null) {
            setState(() {
              _error = _getErrorMessage(failure);
            });
          }
        },
        (tasks) {
          setState(() {
            _importantTasks = tasks;
          });
        },
      );

      controlPointResult.fold(
        (failure) {
          if (_error == null) {
            setState(() {
              _error = _getErrorMessage(failure);
            });
          }
        },
        (tasks) {
          setState(() {
            _controlPointTasks = tasks;
          });
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка при загрузке задач: $e';
      });
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
          // Фильтр для гендиректора/начальника департамента
          if (canViewAll)
            Switch(
              value: _showAll,
              onChanged: (value) {
                setState(() {
                  _showAll = value;
                });
                _loadAllTasks();
              },
            ),
          if (canViewAll)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  _showAll ? 'Все' : 'Мои',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllTasks,
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
          : _isLoading
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
                            onPressed: _loadAllTasks,
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildTasksGrid()),
                        // Кнопки навигации
                        _buildNavigationButtons(),
                      ],
                    ),
    );
  }

  /// Кнопки навигации (На предыдущую, На Главную)
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('На предыдущую'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
            icon: const Icon(Icons.home),
            label: const Text('На Главную'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
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
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        // Левый верхний: Регулярные задачи на сегодня
        _buildRecurringTasksBlock(),
        // Правый верхний: Нерегулярные задачи на сегодня
        _buildIrregularTasksBlock(),
        // Левый нижний: Важные задачи
        _buildImportantTasksBlock(),
        // Правый нижний: Точки контроля
        _buildControlPointsBlock(),
      ],
    );
  }

  /// Блок регулярных задач на сегодня
  Widget _buildRecurringTasksBlock() {
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
                  'Задачи регулярные на сегодня',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Список задач
                Expanded(
                  child: _recurringTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет задач',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _recurringTasks.length,
                          itemBuilder: (context, index) {
                            final task = _recurringTasks[index];
                            return _buildTaskItem(task);
                          },
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
              onTap: () => _showCreateTaskDialog(isRecurring: true),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Блок нерегулярных задач на сегодня
  Widget _buildIrregularTasksBlock() {
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
                  'Задачи нерегулярные на сегодня',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Список задач
                Expanded(
                  child: _irregularTasks.isEmpty
                      ? const Center(
                          child: Text(
                            'Нет задач',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _irregularTasks.length,
                          itemBuilder: (context, index) {
                            final task = _irregularTasks[index];
                            return _buildTaskItem(task);
                          },
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
              onTap: () => _showCreateTaskDialog(isRecurring: false),
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Блок важных задач (целиком)
  Widget _buildImportantTasksBlock() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Важные задачи!',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Список важных задач
            Expanded(
              child: _importantTasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет важных задач',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _importantTasks.length,
                      itemBuilder: (context, index) {
                        final task = _importantTasks[index];
                        return _buildTaskItem(task);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Блок точек контроля (разделен на две части)
  Widget _buildControlPointsBlock() {
    final canViewControlPoints = _canViewAllTasks();
    
    return Card(
      color: Colors.yellow.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Точки контроля',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Разделение на две части
            Expanded(
              child: Row(
                children: [
                  // Левая половина: Истинные точки контроля (только для гендиректора)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.yellow.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Точки контроля',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: !canViewControlPoints
                                ? const Center(
                                    child: Text(
                                      'Доступно только гендиректору',
                                      style: TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  )
                                : _controlPoints.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Нет точек контроля',
                                          style: TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _controlPoints.length,
                                        itemBuilder: (context, index) {
                                          final controlPoint = _controlPoints[index];
                                          return _buildControlPointEntityItem(controlPoint, index + 1);
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Правая половина: Задачи из точек контроля
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Задачи из ТК',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: _controlPointTasks.isEmpty
                              ? const Center(
                                  child: Text(
              'Нет задач',
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _controlPointTasks.length,
                                  itemBuilder: (context, index) {
                                    final task = _controlPointTasks[index];
                                    return _buildControlPointItem(task, index + 1);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  /// Элемент задачи в списке (маленькая строка)
  Widget _buildTaskItem(Task task) {
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
          task.title,
          style: TextStyle(
            fontSize: 11,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
            color: task.status == TaskStatus.completed
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
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
            color: task.status == TaskStatus.completed
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
        // TODO: Открыть детальную страницу точки контроля
        // Navigator.of(context).pushNamed('/control-points/detail', arguments: controlPoint.id);
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

  /// Показывает диалог создания задачи
  void _showCreateTaskDialog({bool? isRecurring}) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(
        businessId: selectedBusiness.id,
        userRepository: userRepository,
        createTaskUseCase: createTaskUseCase,
        isRecurring: isRecurring,
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
  final bool? isRecurring;

  const _CreateTaskDialog({
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
    required this.onSuccess,
    this.isRecurring,
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
                initialTaskData: widget.isRecurring == true
                    ? TaskModel(
                        id: '',
                        businessId: widget.businessId,
                        title: '',
                        isRecurring: true,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      )
                    : null,
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
