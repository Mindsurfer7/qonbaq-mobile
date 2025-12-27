import 'package:dartz/dartz.dart';
import '../entities/workday.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с рабочим днем
/// Реализация находится в data слое
abstract class WorkDayRepository extends Repository {
  /// Начать рабочий день
  Future<Either<Failure, WorkDay>> startWorkDay(String businessId);

  /// Завершить рабочий день
  Future<Either<Failure, WorkDay>> endWorkDay(String businessId);

  /// Отметить отсутствие
  Future<Either<Failure, WorkDay>> markAbsent(String businessId, String reason);

  /// Получить статус рабочего дня на сегодня
  Future<Either<Failure, WorkDay?>> getTodayStatus(String businessId);

  /// Получить статистику за месяц
  Future<Either<Failure, WorkDayStatistics>> getStatistics(
      String businessId, String month);
}





