import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/usecases/get_workday_statistics.dart';
import '../../domain/entities/workday.dart';
import '../providers/profile_provider.dart';
import '../widgets/workday_buttons.dart';

/// Страница табелирования
class TimesheetPage extends StatefulWidget {
  const TimesheetPage({super.key});

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  WorkDayStatistics? _statistics;
  bool _isLoading = false;
  String? _error;
  String _selectedMonth = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _error = 'Компания не выбрана';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final getStatistics = Provider.of<GetWorkDayStatistics>(context, listen: false);
      final result = await getStatistics.call(
        GetWorkDayStatisticsParams(
          businessId: businessId,
          month: _selectedMonth,
        ),
      );

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (statistics) {
          setState(() {
            _statistics = statistics;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Произошла ошибка: $e';
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    final current = DateTime.parse('$_selectedMonth-01');
    final newDate = DateTime(current.year, current.month + delta, 1);
    setState(() {
      _selectedMonth = '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}';
    });
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Табелирование'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
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
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStatistics,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая часть - кнопки рабочего дня
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: const WorkDayButtons(),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    // Правая часть - график и статистика
                    Expanded(
                      flex: 2,
                      child: _buildStatisticsView(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatisticsView() {
    if (_statistics == null) {
      return const Center(child: Text('Нет данных'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Выбор месяца
          _buildMonthSelector(),
          const SizedBox(height: 16),
          // Расширенная статистика
          _buildExtendedStatistics(),
          const SizedBox(height: 16),
          // График отработанных дней
          _buildDaysChart(),
          const SizedBox(height: 16),
          // Детализация по дням
          _buildDaysDetails(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final current = DateTime.parse('$_selectedMonth-01');
    final monthNames = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          '${monthNames[current.month - 1]} ${current.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildExtendedStatistics() {
    final stats = _statistics!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расширенная статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Общее количество часов', '${stats.totalHours.toStringAsFixed(1)} ч'),
            if (stats.avgHoursPerDay != null)
              _buildStatRow('Среднее часов в день', '${stats.avgHoursPerDay!.toStringAsFixed(1)} ч'),
            _buildStatRow('Отработано дней', '${stats.workedDays}'),
            _buildStatRow('Завершено дней', '${stats.completedDays}'),
            _buildStatRow('Начато дней', '${stats.startedDays}'),
            _buildStatRow('Отсутствий', '${stats.absentDays}'),
            _buildStatRow('Норма дней', '${stats.norm.days}'),
            _buildStatRow(
              'Разница с нормой',
              '${stats.daysDifference > 0 ? '+' : ''}${stats.daysDifference}',
              color: stats.isOverNorm
                  ? Colors.green
                  : stats.isUnderNorm
                      ? Colors.red
                      : null,
            ),
            _buildStatRow(
              'Выполнение нормы',
              '${stats.completionPercentage.toStringAsFixed(1)}%',
              color: stats.completionPercentage >= 100
                  ? Colors.green
                  : stats.completionPercentage >= 80
                      ? Colors.orange
                      : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysChart() {
    final stats = _statistics!;
    if (stats.days.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Нет данных для графика')),
        ),
      );
    }

    final maxHours = stats.days.map((d) => d.hours).reduce((a, b) => a > b ? a : b);
    final chartHeight = 150.0;
    final availableHeight = chartHeight - 40; // Вычитаем место для подписей

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'График отработанных дней',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: chartHeight,
              child: stats.days.length > 10
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: stats.days.map((day) {
                          final barHeight = maxHours > 0
                              ? (day.hours / maxHours) * availableHeight
                              : 0.0;
                          final color = day.status == WorkDayStatus.completed
                              ? Colors.green
                              : day.status == WorkDayStatus.started
                                  ? Colors.blue
                                  : Colors.grey;

                          return Container(
                            width: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: barHeight > 0 ? barHeight : 2,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.date.day}',
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${day.hours.toStringAsFixed(1)}ч',
                                  style: const TextStyle(fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: stats.days.map((day) {
                        final barHeight = maxHours > 0
                            ? (day.hours / maxHours) * availableHeight
                            : 0.0;
                        final color = day.status == WorkDayStatus.completed
                            ? Colors.green
                            : day.status == WorkDayStatus.started
                                ? Colors.blue
                                : Colors.grey;

                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: barHeight > 0 ? barHeight : 2,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.date.day}',
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${day.hours.toStringAsFixed(1)}ч',
                                  style: const TextStyle(fontSize: 9),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(Colors.green, 'Завершено'),
                _buildLegendItem(Colors.blue, 'Начато'),
                _buildLegendItem(Colors.grey, 'Отсутствие'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildDaysDetails() {
    final stats = _statistics!;
    if (stats.days.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Детализация по дням',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...stats.days.map((day) {
              final statusText = day.status == WorkDayStatus.completed
                  ? 'Завершено'
                  : day.status == WorkDayStatus.started
                      ? 'Начато'
                      : 'Отсутствие';
              final statusColor = day.status == WorkDayStatus.completed
                  ? Colors.green
                  : day.status == WorkDayStatus.started
                      ? Colors.blue
                      : Colors.grey;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${day.date.day}.${day.date.month.toString().padLeft(2, '0')}.${day.date.year}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${day.hours.toStringAsFixed(1)} ч',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

