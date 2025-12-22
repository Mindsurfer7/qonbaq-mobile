import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/workday.dart';
import '../repositories/workday_repository.dart';

/// Параметры для отметки отсутствия
class MarkAbsentParams {
  final String businessId;
  final String reason;

  MarkAbsentParams({required this.businessId, required this.reason});
}

/// Use Case для отметки отсутствия
class MarkAbsent implements UseCase<WorkDay, MarkAbsentParams> {
  final WorkDayRepository repository;

  MarkAbsent(this.repository);

  @override
  Future<Either<Failure, WorkDay>> call(MarkAbsentParams params) async {
    return await repository.markAbsent(params.businessId, params.reason);
  }
}



