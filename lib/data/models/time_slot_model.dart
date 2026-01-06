import '../../domain/entities/time_slot.dart';
import '../models/model.dart';

/// Модель тайм-слота
class TimeSlotModel extends TimeSlot implements Model {
  const TimeSlotModel({
    required super.id,
    super.employmentId,
    super.resourceId,
    super.serviceId,
    required super.startTime,
    required super.endTime,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'] as String,
      employmentId: json['employmentId'] as String?,
      resourceId: json['resourceId'] as String?,
      serviceId: json['serviceId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static TimeSlotStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return TimeSlotStatus.available;
      case 'BOOKED':
        return TimeSlotStatus.booked;
      case 'UNAVAILABLE':
        return TimeSlotStatus.unavailable;
      default:
        return TimeSlotStatus.available;
    }
  }

  static String _statusToString(TimeSlotStatus status) {
    switch (status) {
      case TimeSlotStatus.available:
        return 'AVAILABLE';
      case TimeSlotStatus.booked:
        return 'BOOKED';
      case TimeSlotStatus.unavailable:
        return 'UNAVAILABLE';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (employmentId != null) 'employmentId': employmentId,
      if (resourceId != null) 'resourceId': resourceId,
      if (serviceId != null) 'serviceId': serviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': _statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания тайм-слота
  Map<String, dynamic> toCreateJson() {
    return {
      if (employmentId != null) 'employmentId': employmentId,
      if (resourceId != null) 'resourceId': resourceId,
      if (serviceId != null) 'serviceId': serviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': _statusToString(status),
    };
  }

  /// Преобразование в JSON для обновления тайм-слота
  Map<String, dynamic> toUpdateJson() {
    return {
      if (employmentId != null) 'employmentId': employmentId,
      if (resourceId != null) 'resourceId': resourceId,
      if (serviceId != null) 'serviceId': serviceId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': _statusToString(status),
    };
  }

  TimeSlot toEntity() {
    return TimeSlot(
      id: id,
      employmentId: employmentId,
      resourceId: resourceId,
      serviceId: serviceId,
      startTime: startTime,
      endTime: endTime,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TimeSlotModel.fromEntity(TimeSlot timeSlot) {
    return TimeSlotModel(
      id: timeSlot.id,
      employmentId: timeSlot.employmentId,
      resourceId: timeSlot.resourceId,
      serviceId: timeSlot.serviceId,
      startTime: timeSlot.startTime,
      endTime: timeSlot.endTime,
      status: timeSlot.status,
      createdAt: timeSlot.createdAt,
      updatedAt: timeSlot.updatedAt,
    );
  }
}

