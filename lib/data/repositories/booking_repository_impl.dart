import 'package:dartz/dartz.dart';
import '../../domain/entities/booking.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../core/error/failures.dart';
import '../models/booking_model.dart';
import '../datasources/booking_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/booking_remote_datasource_impl.dart' show ValidationException;

/// Реализация репозитория бронирований
class BookingRepositoryImpl extends RepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Booking>>> getBookings({
    String? timeSlotId,
    String? serviceId,
    String? businessId,
    BookingStatus? status,
    String? clientId,
  }) async {
    try {
      final bookings = await remoteDataSource.getBookings(
        timeSlotId: timeSlotId,
        serviceId: serviceId,
        businessId: businessId,
        status: status,
        clientId: clientId,
      );
      return Right(bookings.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении бронирований: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> getBookingById(String id) async {
    try {
      final booking = await remoteDataSource.getBookingById(id);
      return Right(booking.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении бронирования: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> createBooking(Booking booking) async {
    try {
      final bookingModel = BookingModel.fromEntity(booking);
      final createdBooking = await remoteDataSource.createBooking(bookingModel);
      return Right(createdBooking.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании бронирования: $e'));
    }
  }

  @override
  Future<Either<Failure, Booking>> updateBookingStatus(String id, BookingStatus status) async {
    try {
      final booking = await remoteDataSource.updateBookingStatus(id, status);
      return Right(booking.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении статуса бронирования: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBooking(String id) async {
    try {
      await remoteDataSource.deleteBooking(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении бронирования: $e'));
    }
  }
}

