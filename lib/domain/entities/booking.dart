import '../entities/entity.dart';
import 'time_slot.dart';
import 'service.dart';

/// Статус бронирования
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

/// Доменная сущность бронирования
class Booking extends Entity {
  final String id;
  final String timeSlotId;
  final String serviceId;
  final String? clientId; // ID клиента (если авторизован)
  final String clientName;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientComment;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Детальные данные (для детальной страницы)
  final TimeSlot? timeSlot;
  final Service? service;

  const Booking({
    required this.id,
    required this.timeSlotId,
    required this.serviceId,
    this.clientId,
    required this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.clientComment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.timeSlot,
    this.service,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Booking &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Booking(id: $id, clientName: $clientName)';
}

