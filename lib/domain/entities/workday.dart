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

/// Детализация рабочего дня
class WorkDayDetail {
  final DateTime date;
  final double hours;
  final WorkDayStatus status;

  const WorkDayDetail({
    required this.date,
    required this.hours,
    required this.status,
  });
}

/// Норма рабочих дней
class WorkDayNorm {
  final int days;

  const WorkDayNorm({required this.days});
}

/// Статистика рабочего дня за месяц
class WorkDayStatistics extends Entity {
  final String businessId;
  final String month; // Формат: YYYY-MM
  final int workedDays;
  final int absentDays;
  
  // Расширенная статистика
  final double totalHours;
  final double? avgHoursPerDay;
  final int daysDifference;
  final bool isOverNorm;
  final bool isUnderNorm;
  final double completionPercentage;
  final WorkDayNorm norm;
  
  // Разбивка по статусам
  final int completedDays;
  final int startedDays;
  
  // Детализация по дням
  final List<WorkDayDetail> days;

  const WorkDayStatistics({
    required this.businessId,
    required this.month,
    required this.workedDays,
    required this.absentDays,
    required this.totalHours,
    this.avgHoursPerDay,
    required this.daysDifference,
    required this.isOverNorm,
    required this.isUnderNorm,
    required this.completionPercentage,
    required this.norm,
    required this.completedDays,
    required this.startedDays,
    required this.days,
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
      'WorkDayStatistics(businessId: $businessId, month: $month, workedDays: $workedDays, absentDays: $absentDays, totalHours: $totalHours)';
}

