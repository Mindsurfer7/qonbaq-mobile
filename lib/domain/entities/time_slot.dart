import '../entities/entity.dart';

/// Статус тайм-слота
enum TimeSlotStatus {
  available,
  booked,
  unavailable,
}

/// Доменная сущность тайм-слота
class TimeSlot extends Entity {
  final String id;
  final String? employmentId; // ID сотрудника
  final String? resourceId; // ID ресурса
  final String? serviceId; // ID услуги
  final DateTime startTime;
  final DateTime endTime;
  final TimeSlotStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimeSlot({
    required this.id,
    this.employmentId,
    this.resourceId,
    this.serviceId,
    required this.startTime,
    required this.endTime,
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
  String toString() => 'TimeSlot(id: $id, startTime: $startTime)';
}

