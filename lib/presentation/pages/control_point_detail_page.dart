import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/control_point.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_control_point.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../core/error/failures.dart';
import '../widgets/user_info_row.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/profile_provider.dart';

/// Детальная страница точки контроля
class ControlPointDetailPage extends StatefulWidget {
  final String controlPointId;

  const ControlPointDetailPage({
    super.key,
    required this.controlPointId,
  });

  @override
  State<ControlPointDetailPage> createState() => _ControlPointDetailPageState();
}

class _ControlPointDetailPageState extends State<ControlPointDetailPage> {
  ControlPoint? _controlPoint;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  
  // Состояние для раскрытых метрик
  final Map<String, bool> _expandedMetrics = {};
  // Загруженные задачи для каждой метрики
  final Map<String, List<Task>> _metricTasks = {};
  // Состояние загрузки для каждой метрики
  final Map<String, bool> _loadingMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadControlPoint();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadControlPoint() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getControlPointUseCase = Provider.of<GetControlPoint>(context, listen: false);
    final result = await getControlPointUseCase.call(widget.controlPointId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке точки контроля'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (controlPoint) {
        setState(() {
          _isLoading = false;
          _controlPoint = controlPoint;
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
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

  String _getUnitText(MeasurementUnit unit, String? customUnit) {
    switch (unit) {
      case MeasurementUnit.kilogram:
        return 'кг';
      case MeasurementUnit.gram:
        return 'г';
      case MeasurementUnit.ton:
        return 'т';
      case MeasurementUnit.meter:
        return 'м';
      case MeasurementUnit.kilometer:
        return 'км';
      case MeasurementUnit.hour:
        return 'ч';
      case MeasurementUnit.minute:
        return 'мин';
      case MeasurementUnit.piece:
        return 'шт';
      case MeasurementUnit.liter:
        return 'л';
      case MeasurementUnit.custom:
        return customUnit ?? 'ед.';
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_controlPoint?.title ?? 'Точка контроля'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadControlPoint,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
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
                        onPressed: _loadControlPoint,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _controlPoint == null
                  ? const Center(child: Text('Точка контроля не найдена'))
                  : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadControlPoint,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок и статус активности
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _controlPoint!.title,
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
                          color: _controlPoint!.isActive
                              ? Colors.green
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _controlPoint!.isActive ? 'Активна' : 'Неактивна',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Важность и напоминание
                  if (_controlPoint!.isImportant || _controlPoint!.dontForget)
                    Row(
                      children: [
                        if (_controlPoint!.isImportant)
                          const Icon(Icons.star,
                              color: Colors.amber, size: 24),
                        if (_controlPoint!.isImportant &&
                            _controlPoint!.dontForget)
                          const SizedBox(width: 8),
                        if (_controlPoint!.dontForget)
                          const Icon(Icons.notifications_active,
                              color: Colors.orange, size: 24),
                      ],
                    ),
                  if (_controlPoint!.isImportant || _controlPoint!.dontForget)
                    const SizedBox(height: 16),

                  // Описание
                  if (_controlPoint!.description != null &&
                      _controlPoint!.description!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          _controlPoint!.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Компания
                  if (_controlPoint!.business != null)
                    _buildInfoRow(
                      'Компания',
                      _controlPoint!.business!.name,
                      Icons.business,
                    ),

                  // Исполнитель
                  if (_controlPoint!.assignee != null)
                    Builder(
                      builder: (context) {
                        final chatRepository = Provider.of<ChatRepository>(
                          context,
                          listen: false,
                        );
                        return UserInfoRow(
                          user: _controlPoint!.assignee,
                          label: 'Исполнитель',
                          icon: Icons.person,
                          chatRepository: chatRepository,
                        );
                      },
                    ),

                  // Поручитель
                  if (_controlPoint!.assigner != null)
                    Builder(
                      builder: (context) {
                        final chatRepository = Provider.of<ChatRepository>(
                          context,
                          listen: false,
                        );
                        return UserInfoRow(
                          user: _controlPoint!.assigner,
                          label: 'Поручил',
                          icon: Icons.person_outline,
                          chatRepository: chatRepository,
                        );
                      },
                    ),

                  // Создатель
                  if (_controlPoint!.creator != null)
                    Builder(
                      builder: (context) {
                        final chatRepository = Provider.of<ChatRepository>(
                          context,
                          listen: false,
                        );
                        return UserInfoRow(
                          user: _controlPoint!.creator,
                          label: 'Создатель',
                          icon: Icons.person_add,
                          chatRepository: chatRepository,
                        );
                      },
                    ),

                  // Частота и интервал
                  _buildInfoRow(
                    'Частота',
                    '${_getFrequencyText(_controlPoint!.frequency)} (каждые ${_controlPoint!.interval})',
                    Icons.repeat,
                  ),

                  // Время создания задачи
                  if (_controlPoint!.timeOfDay != null)
                    _buildInfoRow(
                      'Время создания задачи',
                      _controlPoint!.timeOfDay!,
                      Icons.access_time,
                    ),

                  // Дни недели (для еженедельных)
                  if (_controlPoint!.daysOfWeek != null &&
                      _controlPoint!.daysOfWeek!.isNotEmpty)
                    _buildInfoRow(
                      'Дни недели',
                      _controlPoint!.daysOfWeek!
                          .map((d) => _getDayOfWeekName(d))
                          .join(', '),
                      Icons.calendar_view_week,
                    ),

                  // День месяца (для ежемесячных)
                  if (_controlPoint!.dayOfMonth != null)
                    _buildInfoRow(
                      'День месяца',
                      _controlPoint!.dayOfMonth.toString(),
                      Icons.calendar_today,
                    ),

                  // Дата начала
                  _buildInfoRow(
                    'Дата начала',
                    _formatDate(_controlPoint!.startDate),
                    Icons.play_arrow,
                  ),

                  // Дата окончания
                  if (_controlPoint!.endDate != null)
                    _buildInfoRow(
                      'Дата окончания',
                      _formatDate(_controlPoint!.endDate!),
                      Icons.stop,
                    )
                  else
                    _buildInfoRow(
                      'Дата окончания',
                      'Бесконечно',
                      Icons.all_inclusive,
                    ),

                  // Смещение дедлайна
                  if (_controlPoint!.deadlineOffset != null)
                    _buildInfoRow(
                      'Смещение дедлайна',
                      '${_controlPoint!.deadlineOffset} ч.',
                      Icons.schedule,
                    ),

                  // Наблюдатели
                  if (_controlPoint!.observerIds.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Наблюдатели',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_controlPoint!.observerIds.length} наблюдателей',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Метрики
                  if (_controlPoint!.metrics != null &&
                      _controlPoint!.metrics!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.analytics,
                              size: 24,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Метрики',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_controlPoint!.metrics!.length}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _controlPoint!.metrics!.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final metric = _controlPoint!.metrics![index];
                            return _buildMetricCard(metric, index + 1);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Дата создания и обновления
                  _buildInfoRow(
                    'Создана',
                    _formatDateTime(_controlPoint!.createdAt),
                    Icons.add_circle_outline,
                  ),
                  _buildInfoRow(
                    'Обновлена',
                    _formatDateTime(_controlPoint!.updatedAt),
                    Icons.update,
                  ),

                  // Дата деактивации
                  if (_controlPoint!.deactivatedAt != null)
                    _buildInfoRow(
                      'Деактивирована',
                      _formatDateTime(_controlPoint!.deactivatedAt!),
                      Icons.block,
                      color: Colors.red,
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

  Widget _buildMetricCard(ControlPointMetric metric, int index) {
    final isExpanded = _expandedMetrics[metric.id] ?? false;
    final tasks = _metricTasks[metric.id] ?? [];
    final isLoading = _loadingMetrics[metric.id] ?? false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.purple.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Заголовок метрики (кликабельный)
          InkWell(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            onTap: () {
              setState(() {
                _expandedMetrics[metric.id] = !isExpanded;
              });
              
              // Если раскрываем и еще не загружали задачи
              if (!isExpanded && !_metricTasks.containsKey(metric.id)) {
                _loadTasksForMetric(metric);
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Номер метрики
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.purple.shade300,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Название и значение
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.track_changes,
                              size: 16,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Целевое значение: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${metric.targetValue} ${_getUnitText(metric.unit, metric.customUnit)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Иконка раскрытия
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Раскрываемая область с задачами
          if (isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Нет задач с этой метрикой',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: tasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 4),
                        itemBuilder: (context, taskIndex) {
                          final task = tasks[taskIndex];
                          return _buildTaskMetricItem(task, metric);
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Загружает задачи для метрики
  Future<void> _loadTasksForMetric(ControlPointMetric metric) async {
    if (_controlPoint == null) return;

    setState(() {
      _loadingMetrics[metric.id] = true;
    });

    try {
      final getTasksUseCase = Provider.of<GetTasks>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
      final selectedBusiness = profileProvider.selectedBusiness;

      if (selectedBusiness == null) {
        setState(() {
          _loadingMetrics[metric.id] = false;
        });
        return;
      }

      final result = await getTasksUseCase.call(
        GetTasksParams(
          businessId: selectedBusiness.id,
          controlPointId: _controlPoint!.id,
          limit: 100,
        ),
      );

      result.fold(
        (failure) {
          setState(() {
            _loadingMetrics[metric.id] = false;
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
        (tasks) {
          // Фильтруем задачи, которые содержат эту метрику
          // Показываем все задачи из точки контроля, так как каждая задача
          // может содержать все метрики точки контроля
          setState(() {
            _loadingMetrics[metric.id] = false;
            _metricTasks[metric.id] = tasks;
          });
        },
      );
    } catch (e) {
      setState(() {
        _loadingMetrics[metric.id] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при загрузке задач: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Элемент задачи в списке метрики
  Widget _buildTaskMetricItem(Task task, ControlPointMetric metric) {
    // Находим фактическое значение метрики в задаче
    TaskIndicator? taskMetric;
    if (task.indicators != null && task.indicators!.isNotEmpty) {
      try {
        taskMetric = task.indicators!.firstWhere(
          (indicator) => indicator.name == metric.name,
        );
      } catch (e) {
        // Метрика не найдена в задаче
        taskMetric = null;
      }
    }

    final actualValue = taskMetric?.actualValue;
    final targetValue = metric.targetValue;
    final isCompleted = task.status == TaskStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey.shade50,
      child: InkWell(
        onTap: () {
          context.go(
            '/tasks/detail',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Статус задачи
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              // Название задачи
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Целевое: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${targetValue} ${_getUnitText(metric.unit, metric.customUnit)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        if (actualValue != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            'Факт: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${actualValue} ${_getUnitText(metric.unit, metric.customUnit)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: actualValue >= targetValue
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Иконка перехода
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayOfWeekName(int day) {
    switch (day) {
      case 0:
        return 'Воскресенье';
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      default:
        return 'День $day';
    }
  }
}
