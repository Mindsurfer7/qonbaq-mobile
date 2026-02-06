import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/usecases/get_time_slots_by_service.dart';
import '../../domain/repositories/time_slot_repository.dart';

/// Страница детальной информации об услуге с тайм-слотами
class ServiceDetailPage extends StatefulWidget {
  final Service service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  List<TimeSlotGroup> _timeSlotGroups = [];
  bool _isLoading = false;
  String? _error;

  // Кэш для группированных данных
  Map<DateTime, Map<String?, List<TimeSlot>>>? _groupedCache;
  List<DateTime>? _sortedDatesCache;

  @override
  void initState() {
    super.initState();
    _loadTimeSlots();
  }

  Future<void> _loadTimeSlots() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final timeSlotRepository = Provider.of<TimeSlotRepository>(
      context,
      listen: false,
    );
    final getTimeSlotsByService = GetTimeSlotsByService(timeSlotRepository);
    final result = await getTimeSlotsByService.call(widget.service.id);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      result.fold(
        (failure) {
          _error = failure.message;
          _groupedCache = null;
          _sortedDatesCache = null;
        },
        (groups) {
          _timeSlotGroups = groups;
          _error = null;
          // Инвалидируем кэш при обновлении данных
          _groupedCache = null;
          _sortedDatesCache = null;
        },
      );
    });
  }

  /// Группирует тайм-слоты по дате, затем по исполнителю
  Map<DateTime, Map<String?, List<TimeSlot>>> _groupTimeSlotsByDateAndExecutor(
    List<TimeSlotGroup> groups,
  ) {
    final result = <DateTime, Map<String?, List<TimeSlot>>>{};

    for (final group in groups) {
      for (final slot in group.timeSlots) {
        // Получаем дату без времени
        final date = DateTime(
          slot.startTime.year,
          slot.startTime.month,
          slot.startTime.day,
        );

        // Используем executorName как ключ (null для RESOURCE_BASED)
        final executorKey = group.executorName;

        if (!result.containsKey(date)) {
          result[date] = <String?, List<TimeSlot>>{};
        }

        if (!result[date]!.containsKey(executorKey)) {
          result[date]![executorKey] = <TimeSlot>[];
        }

        result[date]![executorKey]!.add(slot);
      }
    }

    // Сортируем тайм-слоты по времени начала
    for (final dateMap in result.values) {
      for (final slots in dateMap.values) {
        slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      }
    }

    return result;
  }

  String _formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Сегодня';
    } else if (dateOnly == tomorrow) {
      return 'Завтра';
    } else {
      return DateFormat('d MMMM yyyy', 'ru').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTimeSlots,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTimeSlots,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : _buildTimeSlotsList(),
    );
  }

  Widget _buildTimeSlotsList() {
    if (_timeSlotGroups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет доступных тайм-слотов'),
        ),
      );
    }

    // Используем кэш или вычисляем заново
    final grouped =
        _groupedCache ??= _groupTimeSlotsByDateAndExecutor(_timeSlotGroups);
    final sortedDates = _sortedDatesCache ??= grouped.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет доступных тайм-слотов'),
        ),
      );
    }

    // Строим список sliver элементов для полной виртуализации
    final slivers = <Widget>[];

    for (final date in sortedDates) {
      final executorsMap = grouped[date]!;
      final executors = executorsMap.keys.toList();

      // Заголовок даты
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          sliver: SliverToBoxAdapter(
            child: RepaintBoundary(
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                  child: Text(
                    _formatDate(date),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Для каждого исполнителя
      for (final executorName in executors) {
        final slots = executorsMap[executorName]!;

        // Заголовок исполнителя
        slivers.add(
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 8),
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        );
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                executorName ?? 'Ресурс',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );

        // Тайм-слоты - виртуализированный SliverGrid
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 3,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildTimeSlotChip(slots[index]);
              }, childCount: slots.length),
            ),
          ),
        );

        // Отступ после группы тайм-слотов
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 16)));
      }
    }

    return RefreshIndicator(
      onRefresh: _loadTimeSlots,
      child: CustomScrollView(slivers: slivers),
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot) {
    final status = slot.status;
    final statusColor = status.color;
    final statusIcon = status.icon;
    final isSelectable = status == TimeSlotStatus.available;

    // Мемоизируем форматирование времени
    final timeText =
        '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}';

    // Используем кастомный виджет вместо FilterChip для лучшей производительности
    return RepaintBoundary(
      child: InkWell(
        onTap: isSelectable ? null : null, // Пока не реализовано бронирование
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minWidth: 0), // Позволяет сжиматься
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                statusIcon,
                size: 14,
                color: statusColor.withOpacity(isSelectable ? 1.0 : 0.7),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  timeText,
                  style: TextStyle(
                    color: statusColor.withOpacity(isSelectable ? 1.0 : 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
