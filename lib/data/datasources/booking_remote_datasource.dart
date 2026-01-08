import '../../domain/entities/booking.dart';
import '../models/booking_model.dart';

/// Интерфейс удаленного источника данных для бронирований
abstract class BookingRemoteDataSource {
  /// Получить список бронирований
  Future<List<BookingModel>> getBookings({
    String? timeSlotId,
    String? serviceId,
    String? businessId,
    BookingStatus? status,
    String? clientId,
  });

  /// Получить бронирование по ID
  Future<BookingModel> getBookingById(String id);

  /// Создать бронирование
  Future<BookingModel> createBooking(BookingModel booking);

  /// Изменить статус бронирования
  Future<BookingModel> updateBookingStatus(String id, BookingStatus status);

  /// Удалить бронирование
  Future<void> deleteBooking(String id);
}


