import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/usecases/get_time_slots_by_service.dart';
import '../../domain/repositories/time_slot_repository.dart';

/// Страница детальной информации об услуге с тайм-слотами
class ServiceDetailPage extends StatefulWidget {
  final Service service;

  const ServiceDetailPage({
    super.key,
    required this.service,
  });

  @override
  State<ServiceDetailPage> createState() => _ServiceDetailPageState();
}

class _ServiceDetailPageState extends State<ServiceDetailPage> {
  List<TimeSlotGroup> _timeSlotGroups = [];
  bool _isLoading = false;
  String? _error;

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
        (failure) => _error = failure.message,
        (groups) {
          _timeSlotGroups = groups;
          _error = null;
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
      body: _isLoading
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

    final grouped = _groupTimeSlotsByDateAndExecutor(_timeSlotGroups);
    final sortedDates = grouped.keys.toList()..sort();

    if (sortedDates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('Нет доступных тайм-слотов'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTimeSlots,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: sortedDates.length,
        itemBuilder: (context, dateIndex) {
          final date = sortedDates[dateIndex];
          final executorsMap = grouped[date]!;
          final executors = executorsMap.keys.toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок с датой
                Container(
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
                // Исполнители и тайм-слоты
                ...executors.map((executorName) {
                  final slots = executorsMap[executorName]!;
                  return _buildExecutorSection(executorName, slots);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExecutorSection(String? executorName, List<TimeSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок исполнителя
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            executorName ?? 'Ресурс',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        // Тайм-слоты
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots.map((slot) {
              return _buildTimeSlotChip(slot);
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimeSlotChip(TimeSlot slot) {
    final isAvailable = slot.isAvailable;
    
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: FilterChip(
        label: Text(
          '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
        ),
        selected: false,
        onSelected: null, // Пока не реализовано бронирование
        avatar: Icon(
          isAvailable ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: isAvailable ? Colors.green : Colors.grey,
        ),
        backgroundColor: isAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        labelStyle: TextStyle(
          color: isAvailable ? Colors.green.shade700 : Colors.grey.shade700,
        ),
      ),
    );
  }
}

