import '../../domain/entities/booking.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/entities/service.dart';
import '../models/model.dart';
import 'time_slot_model.dart';
import 'service_model.dart';

/// Модель бронирования
class BookingModel extends Booking implements Model {
  const BookingModel({
    required super.id,
    required super.timeSlotId,
    required super.serviceId,
    super.clientId,
    required super.clientName,
    super.clientPhone,
    super.clientEmail,
    super.clientComment,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.timeSlot,
    super.service,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Парсинг timeSlot
    TimeSlot? timeSlot;
    if (json['timeSlot'] != null) {
      timeSlot = TimeSlotModel.fromJson(json['timeSlot'] as Map<String, dynamic>).toEntity();
    }

    // Парсинг service
    Service? service;
    if (json['service'] != null) {
      service = ServiceModel.fromJson(json['service'] as Map<String, dynamic>).toEntity();
    }

    return BookingModel(
      id: json['id'] as String,
      timeSlotId: json['timeSlotId'] as String,
      serviceId: json['serviceId'] as String,
      clientId: json['clientId'] as String?,
      clientName: json['clientName'] as String,
      clientPhone: json['clientPhone'] as String?,
      clientEmail: json['clientEmail'] as String?,
      clientComment: json['clientComment'] as String?,
      status: _parseStatus(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      timeSlot: timeSlot,
      service: service,
    );
  }

  static BookingStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return BookingStatus.pending;
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      case 'COMPLETED':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }

  static String _statusToString(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.completed:
        return 'COMPLETED';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timeSlotId': timeSlotId,
      'serviceId': serviceId,
      if (clientId != null) 'clientId': clientId,
      'clientName': clientName,
      if (clientPhone != null) 'clientPhone': clientPhone,
      if (clientEmail != null) 'clientEmail': clientEmail,
      if (clientComment != null) 'clientComment': clientComment,
      'status': _statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания бронирования
  Map<String, dynamic> toCreateJson() {
    return {
      'timeSlotId': timeSlotId,
      'serviceId': serviceId,
      'clientName': clientName,
      if (clientPhone != null && clientPhone!.isNotEmpty) 'clientPhone': clientPhone,
      if (clientEmail != null && clientEmail!.isNotEmpty) 'clientEmail': clientEmail,
      if (clientComment != null && clientComment!.isNotEmpty) 'clientComment': clientComment,
    };
  }

  Booking toEntity() {
    return Booking(
      id: id,
      timeSlotId: timeSlotId,
      serviceId: serviceId,
      clientId: clientId,
      clientName: clientName,
      clientPhone: clientPhone,
      clientEmail: clientEmail,
      clientComment: clientComment,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timeSlot: timeSlot,
      service: service,
    );
  }

  factory BookingModel.fromEntity(Booking booking) {
    return BookingModel(
      id: booking.id,
      timeSlotId: booking.timeSlotId,
      serviceId: booking.serviceId,
      clientId: booking.clientId,
      clientName: booking.clientName,
      clientPhone: booking.clientPhone,
      clientEmail: booking.clientEmail,
      clientComment: booking.clientComment,
      status: booking.status,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
      timeSlot: booking.timeSlot,
      service: booking.service,
    );
  }
}

