import 'package:flutter/material.dart';
import '../entities/entity.dart';

/// Статус тайм-слота
enum TimeSlotStatus {
  available,  // Свободен - можно забронировать
  booked,     // Занят - уже есть запись
  blocked,    // Заблокирован - перерыв, отгул, недоступен
}

/// Доменная сущность тайм-слота
class TimeSlot extends Entity {
  final String id;
  final String serviceId;
  final String? employmentId; // ID исполнителя (может быть null для RESOURCE_BASED)
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable; // Deprecated: используйте status
  final TimeSlotStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeSlot({
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TimeSlot(id: $id, startTime: $startTime, endTime: $endTime)';
}

/// Группа тайм-слотов по исполнителю
class TimeSlotGroup extends Entity {
  final String serviceId;
  final String serviceName;
  final String? employmentId; // null для RESOURCE_BASED услуг
  final String? executorName; // null для RESOURCE_BASED услуг
  final List<TimeSlot> timeSlots;

  const TimeSlotGroup({
    required this.serviceId,
    required this.serviceName,
    this.employmentId,
    this.executorName,
    required this.timeSlots,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlotGroup &&
          runtimeType == other.runtimeType &&
          serviceId == other.serviceId &&
          employmentId == other.employmentId;

  @override
  int get hashCode => serviceId.hashCode ^ employmentId.hashCode;

  @override
  String toString() => 'TimeSlotGroup(serviceId: $serviceId, executorName: $executorName, slots: ${timeSlots.length})';
}

/// Extension для получения цвета и иконки по статусу тайм-слота
extension TimeSlotStatusExtension on TimeSlotStatus {
  /// Получить цвет для статуса
  /// - available: зеленый
  /// - booked: желтый
  /// - blocked: красный
  Color get color {
    switch (this) {
      case TimeSlotStatus.available:
        return Colors.green;
      case TimeSlotStatus.booked:
        return Colors.amber;
      case TimeSlotStatus.blocked:
        return Colors.red;
    }
  }

  /// Получить иконку для статуса
  IconData get icon {
    switch (this) {
      case TimeSlotStatus.available:
        return Icons.check_circle;
      case TimeSlotStatus.booked:
        return Icons.event_busy;
      case TimeSlotStatus.blocked:
        return Icons.block;
    }
  }

  /// Получить текст статуса
  String get label {
    switch (this) {
      case TimeSlotStatus.available:
        return 'Свободен';
      case TimeSlotStatus.booked:
        return 'Занят';
      case TimeSlotStatus.blocked:
        return 'Заблокирован';
    }
  }
}
