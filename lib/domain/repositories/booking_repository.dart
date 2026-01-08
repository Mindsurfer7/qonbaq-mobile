import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/booking.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с бронированиями
abstract class BookingRepository extends Repository {
  /// Получить список бронирований
  Future<Either<Failure, List<Booking>>> getBookings({
    String? timeSlotId,
    String? serviceId,
    String? businessId,
    BookingStatus? status,
    String? clientId,
  });

  /// Получить бронирование по ID
  Future<Either<Failure, Booking>> getBookingById(String id);

  /// Создать бронирование
  Future<Either<Failure, Booking>> createBooking(Booking booking);

  /// Изменить статус бронирования
  Future<Either<Failure, Booking>> updateBookingStatus(String id, BookingStatus status);

  /// Удалить бронирование
  Future<Either<Failure, void>> deleteBooking(String id);
}



