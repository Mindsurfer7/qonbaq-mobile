import '../entities/entity.dart';

/// Статус рабочего дня
enum WorkDayStatus {
  started,
  completed,
  absent,
}

/// Доменная сущность рабочего дня
class WorkDay extends Entity {
  final String id;
  final String businessId;
  final WorkDayStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? reason;
  final DateTime date;

  const WorkDay({
    required this.id,
    required this.businessId,
    required this.status,
    this.startTime,
    this.endTime,
    this.reason,
    required this.date,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkDay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          businessId == other.businessId &&
          date == other.date;

  @override
  int get hashCode => id.hashCode ^ businessId.hashCode ^ date.hashCode;

  @override
  String toString() =>
      'WorkDay(id: $id, businessId: $businessId, status: $status, date: $date)';
}

/// Статистика рабочего дня за месяц
class WorkDayStatistics extends Entity {
  final String businessId;
  final String month; // Формат: YYYY-MM
  final int workedDays;
  final int absentDays;

  const WorkDayStatistics({
    required this.businessId,
    required this.month,
    required this.workedDays,
    required this.absentDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkDayStatistics &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          month == other.month;

  @override
  int get hashCode => businessId.hashCode ^ month.hashCode;

  @override
  String toString() =>
      'WorkDayStatistics(businessId: $businessId, month: $month, workedDays: $workedDays, absentDays: $absentDays)';
}

