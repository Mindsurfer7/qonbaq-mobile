import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/workday.dart';
import '../repositories/workday_repository.dart';

/// Параметры для завершения рабочего дня
class EndWorkDayParams {
  final String businessId;

  EndWorkDayParams({required this.businessId});
}

/// Use Case для завершения рабочего дня
class EndWorkDay implements UseCase<WorkDay, EndWorkDayParams> {
  final WorkDayRepository repository;

  EndWorkDay(this.repository);

  @override
  Future<Either<Failure, WorkDay>> call(EndWorkDayParams params) async {
    return await repository.endWorkDay(params.businessId);
  }
}






