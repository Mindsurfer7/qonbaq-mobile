import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/workday.dart';
import '../repositories/workday_repository.dart';

/// Параметры для получения статуса рабочего дня
class GetWorkDayStatusParams {
  final String businessId;

  GetWorkDayStatusParams({required this.businessId});
}

/// Use Case для получения статуса рабочего дня на сегодня
class GetWorkDayStatus implements UseCase<WorkDay?, GetWorkDayStatusParams> {
  final WorkDayRepository repository;

  GetWorkDayStatus(this.repository);

  @override
  Future<Either<Failure, WorkDay?>> call(GetWorkDayStatusParams params) async {
    return await repository.getTodayStatus(params.businessId);
  }
}






