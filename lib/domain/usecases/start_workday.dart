import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/workday.dart';
import '../repositories/workday_repository.dart';

/// Параметры для начала рабочего дня
class StartWorkDayParams {
  final String businessId;

  StartWorkDayParams({required this.businessId});
}

/// Use Case для начала рабочего дня
class StartWorkDay implements UseCase<WorkDay, StartWorkDayParams> {
  final WorkDayRepository repository;

  StartWorkDay(this.repository);

  @override
  Future<Either<Failure, WorkDay>> call(StartWorkDayParams params) async {
    return await repository.startWorkDay(params.businessId);
  }
}



