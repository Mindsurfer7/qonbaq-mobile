import '../../domain/entities/workday.dart';
import '../models/model.dart';

/// Модель рабочего дня
class WorkDayModel extends WorkDay implements Model {
  const WorkDayModel({
    required super.id,
    required super.businessId,
    required super.status,
    super.startTime,
    super.endTime,
    super.reason,
    required super.date,
  });

  factory WorkDayModel.fromJson(Map<String, dynamic> json) {
    return WorkDayModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      status: _parseStatus(json['status'] as String),
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      reason: json['reason'] as String?,
      date: DateTime.parse(json['date'] as String),
    );
  }

  static WorkDayStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'STARTED':
        return WorkDayStatus.started;
      case 'COMPLETED':
        return WorkDayStatus.completed;
      case 'ABSENT':
        return WorkDayStatus.absent;
      default:
        return WorkDayStatus.started;
    }
  }

  static String _statusToString(WorkDayStatus status) {
    switch (status) {
      case WorkDayStatus.started:
        return 'STARTED';
      case WorkDayStatus.completed:
        return 'COMPLETED';
      case WorkDayStatus.absent:
        return 'ABSENT';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'status': _statusToString(status),
      if (startTime != null) 'startTime': startTime!.toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toIso8601String(),
      if (reason != null) 'reason': reason,
      'date': date.toIso8601String(),
    };
  }

  WorkDay toEntity() {
    return WorkDay(
      id: id,
      businessId: businessId,
      status: status,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
      date: date,
    );
  }

  factory WorkDayModel.fromEntity(WorkDay workDay) {
    return WorkDayModel(
      id: workDay.id,
      businessId: workDay.businessId,
      status: workDay.status,
      startTime: workDay.startTime,
      endTime: workDay.endTime,
      reason: workDay.reason,
      date: workDay.date,
    );
  }
}

/// Модель детализации рабочего дня
class WorkDayDetailModel extends WorkDayDetail {
  const WorkDayDetailModel({
    required super.date,
    required super.hours,
    required super.status,
  });

  factory WorkDayDetailModel.fromJson(Map<String, dynamic> json) {
    return WorkDayDetailModel(
      date: DateTime.parse(json['date'] as String),
      hours: (json['hours'] as num?)?.toDouble() ?? 0.0,
      status: WorkDayModel._parseStatus(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'hours': hours,
      'status': WorkDayModel._statusToString(status),
    };
  }
}

/// Модель нормы рабочих дней
class WorkDayNormModel extends WorkDayNorm {
  const WorkDayNormModel({required super.days});

  factory WorkDayNormModel.fromJson(Map<String, dynamic> json) {
    return WorkDayNormModel(
      days: json['days'] as int? ?? 22,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
    };
  }
}

/// Модель статистики рабочего дня
class WorkDayStatisticsModel extends WorkDayStatistics implements Model {
  const WorkDayStatisticsModel({
    required super.businessId,
    required super.month,
    required super.workedDays,
    required super.absentDays,
    required super.totalHours,
    super.avgHoursPerDay,
    required super.daysDifference,
    required super.isOverNorm,
    required super.isUnderNorm,
    required super.completionPercentage,
    required super.norm,
    required super.completedDays,
    required super.startedDays,
    required super.days,
  });

  factory WorkDayStatisticsModel.fromJson(
    Map<String, dynamic> json, {
    String? businessId,
  }) {
    // Извлекаем данные из вложенной структуры
    final period = json['period'] as Map<String, dynamic>?;
    final statistics = json['statistics'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final normJson = json['norm'] as Map<String, dynamic>? ?? <String, dynamic>{'days': 22};
    final workDaysJson = json['workDays'] as List<dynamic>? ?? [];
    
    // Месяц из period или из корня
    final month = period?['month'] as String? ?? 
                  json['month'] as String? ?? 
                  '';
    
    // businessId должен передаваться извне, так как его нет в ответе API
    final finalBusinessId = businessId ?? json['businessId'] as String? ?? '';
    
    // Безопасное извлечение числовых значений
    int? _getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return null;
    }
    
    double? _getDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return null;
    }
    
    return WorkDayStatisticsModel(
      businessId: finalBusinessId,
      month: month,
      workedDays: _getInt(statistics['workedDays']) ?? 0,
      absentDays: _getInt(statistics['absentDays']) ?? 0,
      totalHours: _getDouble(statistics['totalHours']) ?? 0.0,
      avgHoursPerDay: _getDouble(statistics['avgHoursPerDay']),
      daysDifference: _getInt(statistics['daysDifference']) ?? 0,
      isOverNorm: statistics['isOverNorm'] as bool? ?? false,
      isUnderNorm: statistics['isUnderNorm'] as bool? ?? false,
      completionPercentage: _getDouble(statistics['completionPercentage']) ?? 0.0,
      norm: WorkDayNormModel.fromJson(normJson),
      completedDays: _getInt(statistics['completedDays']) ?? 0,
      startedDays: _getInt(statistics['startedDays']) ?? 0,
      days: workDaysJson
          .map((day) => WorkDayDetailModel.fromJson(day as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'month': month,
      'workedDays': workedDays,
      'absentDays': absentDays,
      'totalHours': totalHours,
      if (avgHoursPerDay != null) 'avgHoursPerDay': avgHoursPerDay,
      'daysDifference': daysDifference,
      'isOverNorm': isOverNorm,
      'isUnderNorm': isUnderNorm,
      'completionPercentage': completionPercentage,
      'norm': (norm as WorkDayNormModel).toJson(),
      'completedDays': completedDays,
      'startedDays': startedDays,
      'days': days.map((day) => (day as WorkDayDetailModel).toJson()).toList(),
    };
  }

  WorkDayStatistics toEntity() {
    return WorkDayStatistics(
      businessId: businessId,
      month: month,
      workedDays: workedDays,
      absentDays: absentDays,
      totalHours: totalHours,
      avgHoursPerDay: avgHoursPerDay,
      daysDifference: daysDifference,
      isOverNorm: isOverNorm,
      isUnderNorm: isUnderNorm,
      completionPercentage: completionPercentage,
      norm: norm,
      completedDays: completedDays,
      startedDays: startedDays,
      days: days,
    );
  }

  factory WorkDayStatisticsModel.fromEntity(WorkDayStatistics statistics) {
    return WorkDayStatisticsModel(
      businessId: statistics.businessId,
      month: statistics.month,
      workedDays: statistics.workedDays,
      absentDays: statistics.absentDays,
      totalHours: statistics.totalHours,
      avgHoursPerDay: statistics.avgHoursPerDay,
      daysDifference: statistics.daysDifference,
      isOverNorm: statistics.isOverNorm,
      isUnderNorm: statistics.isUnderNorm,
      completionPercentage: statistics.completionPercentage,
      norm: statistics.norm,
      completedDays: statistics.completedDays,
      startedDays: statistics.startedDays,
      days: statistics.days,
    );
  }
}

