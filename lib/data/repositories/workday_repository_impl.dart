import 'package:dartz/dartz.dart';
import '../../domain/entities/workday.dart';
import '../../domain/repositories/workday_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/workday_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/workday_remote_datasource_impl.dart';

/// Реализация репозитория рабочего дня
/// Использует Remote DataSource
class WorkDayRepositoryImpl extends RepositoryImpl implements WorkDayRepository {
  final WorkDayRemoteDataSource remoteDataSource;

  WorkDayRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, WorkDay>> startWorkDay(String businessId) async {
    try {
      final workDay = await remoteDataSource.startWorkDay(businessId);
      return Right(workDay.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при начале рабочего дня: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkDay>> endWorkDay(String businessId, {String? action}) async {
    try {
      final workDay = await remoteDataSource.endWorkDay(businessId, action: action);
      return Right(workDay.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при завершении рабочего дня: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkDay>> markAbsent(
      String businessId, String reason) async {
    try {
      final workDay = await remoteDataSource.markAbsent(businessId, reason);
      return Right(workDay.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при отметке отсутствия: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkDay?>> getTodayStatus(String businessId) async {
    try {
      final workDay = await remoteDataSource.getTodayStatus(businessId);
      return Right(workDay?.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении статуса: $e'));
    }
  }

  @override
  Future<Either<Failure, WorkDayStatistics>> getStatistics(
      String businessId, String month) async {
    try {
      final statistics = await remoteDataSource.getStatistics(businessId, month);
      return Right(statistics.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении статистики: $e'));
    }
  }
}

