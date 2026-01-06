import 'package:dartz/dartz.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';
import '../../core/error/failures.dart';
import '../models/time_slot_model.dart';
import '../datasources/time_slot_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/time_slot_remote_datasource_impl.dart' show ValidationException;

/// Реализация репозитория тайм-слотов
class TimeSlotRepositoryImpl extends RepositoryImpl implements TimeSlotRepository {
  final TimeSlotRemoteDataSource remoteDataSource;

  TimeSlotRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<TimeSlot>>> getTimeSlots({
    String? employmentId,
    String? resourceId,
    String? serviceId,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TimeSlotStatus? status,
  }) async {
    try {
      final timeSlots = await remoteDataSource.getTimeSlots(
        employmentId: employmentId,
        resourceId: resourceId,
        serviceId: serviceId,
        date: date,
        from: from,
        to: to,
        status: status,
      );
      return Right(timeSlots.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении тайм-слотов: $e'));
    }
  }

  @override
  Future<Either<Failure, TimeSlot>> getTimeSlotById(String id) async {
    try {
      final timeSlot = await remoteDataSource.getTimeSlotById(id);
      return Right(timeSlot.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении тайм-слота: $e'));
    }
  }

  @override
  Future<Either<Failure, TimeSlot>> createTimeSlot(TimeSlot timeSlot) async {
    try {
      final timeSlotModel = TimeSlotModel.fromEntity(timeSlot);
      final createdTimeSlot = await remoteDataSource.createTimeSlot(timeSlotModel);
      return Right(createdTimeSlot.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании тайм-слота: $e'));
    }
  }

  @override
  Future<Either<Failure, List<TimeSlot>>> generateTimeSlots(Map<String, dynamic> params) async {
    try {
      final timeSlots = await remoteDataSource.generateTimeSlots(params);
      return Right(timeSlots.map((model) => model.toEntity()).toList());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при генерации тайм-слотов: $e'));
    }
  }

  @override
  Future<Either<Failure, TimeSlot>> updateTimeSlot(String id, TimeSlot timeSlot) async {
    try {
      final timeSlotModel = TimeSlotModel.fromEntity(timeSlot);
      final updatedTimeSlot = await remoteDataSource.updateTimeSlot(id, timeSlotModel);
      return Right(updatedTimeSlot.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении тайм-слота: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTimeSlot(String id) async {
    try {
      await remoteDataSource.deleteTimeSlot(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении тайм-слота: $e'));
    }
  }
}

