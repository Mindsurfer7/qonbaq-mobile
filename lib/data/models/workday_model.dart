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

/// Модель статистики рабочего дня
class WorkDayStatisticsModel extends WorkDayStatistics implements Model {
  const WorkDayStatisticsModel({
    required super.businessId,
    required super.month,
    required super.workedDays,
    required super.absentDays,
  });

  factory WorkDayStatisticsModel.fromJson(Map<String, dynamic> json) {
    return WorkDayStatisticsModel(
      businessId: json['businessId'] as String,
      month: json['month'] as String,
      workedDays: json['workedDays'] as int,
      absentDays: json['absentDays'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'month': month,
      'workedDays': workedDays,
      'absentDays': absentDays,
    };
  }

  WorkDayStatistics toEntity() {
    return WorkDayStatistics(
      businessId: businessId,
      month: month,
      workedDays: workedDays,
      absentDays: absentDays,
    );
  }

  factory WorkDayStatisticsModel.fromEntity(WorkDayStatistics statistics) {
    return WorkDayStatisticsModel(
      businessId: statistics.businessId,
      month: statistics.month,
      workedDays: statistics.workedDays,
      absentDays: statistics.absentDays,
    );
  }
}

