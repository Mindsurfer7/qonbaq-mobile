import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/workday.dart';
import '../repositories/workday_repository.dart';

/// Параметры для получения статистики рабочего дня
class GetWorkDayStatisticsParams {
  final String businessId;
  final String month; // Формат: YYYY-MM

  GetWorkDayStatisticsParams({required this.businessId, required this.month});
}

/// Use Case для получения статистики рабочего дня за месяц
class GetWorkDayStatistics
    implements UseCase<WorkDayStatistics, GetWorkDayStatisticsParams> {
  final WorkDayRepository repository;

  GetWorkDayStatistics(this.repository);

  @override
  Future<Either<Failure, WorkDayStatistics>> call(
      GetWorkDayStatisticsParams params) async {
    return await repository.getStatistics(params.businessId, params.month);
  }
}

