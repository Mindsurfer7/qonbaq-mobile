import '../../domain/entities/time_slot.dart';

/// Модель тайм-слота для data слоя
class TimeSlotModel {
  final String id;
  final String serviceId;
  final String? employmentId;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final TimeSlotStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeSlotModel({
    required this.id,
    required this.serviceId,
    this.employmentId,
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    final isAvailable = json['isAvailable'] as bool? ?? true;
    final statusString = json['status'] as String?;

    // Парсим статус из JSON, если не указан - определяем по isAvailable
    TimeSlotStatus status;
    if (statusString != null) {
      switch (statusString.toUpperCase()) {
        case 'AVAILABLE':
          status = TimeSlotStatus.available;
          break;
        case 'BOOKED':
          status = TimeSlotStatus.booked;
          break;
        case 'BLOCKED':
        case 'UNAVAILABLE': // Поддержка старого формата
          status = TimeSlotStatus.blocked;
          break;
        default:
          status =
              isAvailable ? TimeSlotStatus.available : TimeSlotStatus.blocked;
      }
    } else {
      // Если статус не пришел, определяем по isAvailable
      status = isAvailable ? TimeSlotStatus.available : TimeSlotStatus.blocked;
    }

    return TimeSlotModel(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      employmentId: json['employmentId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isAvailable: isAvailable,
      status: status,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  TimeSlot toEntity() {
    return TimeSlot(
      id: id,
      serviceId: serviceId,
      employmentId: employmentId,
      startTime: startTime,
      endTime: endTime,
      isAvailable: isAvailable,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TimeSlotModel.fromEntity(TimeSlot timeSlot) {
    return TimeSlotModel(
      id: timeSlot.id,
      serviceId: timeSlot.serviceId,
      employmentId: timeSlot.employmentId,
      startTime: timeSlot.startTime,
      endTime: timeSlot.endTime,
      isAvailable: timeSlot.isAvailable,
      status: timeSlot.status,
      createdAt: timeSlot.createdAt,
      updatedAt: timeSlot.updatedAt,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'serviceId': serviceId,
      if (employmentId != null) 'employmentId': employmentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isAvailable': isAvailable,
    };
  }
}

/// Модель группы тайм-слотов для data слоя
class TimeSlotGroupModel {
  final String serviceId;
  final String serviceName;
  final String? employmentId;
  final String? executorName;
  final List<TimeSlotModel> timeSlots;

  const TimeSlotGroupModel({
    required this.serviceId,
    required this.serviceName,
    this.employmentId,
    this.executorName,
    required this.timeSlots,
  });

  factory TimeSlotGroupModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotGroupModel(
      serviceId: json['serviceId'] as String,
      serviceName: json['serviceName'] as String,
      employmentId: json['employmentId'] as String?,
      executorName: json['executorName'] as String?,
      timeSlots:
          (json['timeSlots'] as List<dynamic>?)
              ?.map(
                (item) => TimeSlotModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  TimeSlotGroup toEntity() {
    return TimeSlotGroup(
      serviceId: serviceId,
      serviceName: serviceName,
      employmentId: employmentId,
      executorName: executorName,
      timeSlots: timeSlots.map((model) => model.toEntity()).toList(),
    );
  }
}
