import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/transit.dart';
import '../repositories/financial_repository.dart';

class CreateTransit implements UseCase<Transit, Transit> {
  final FinancialRepository repository;

  CreateTransit(this.repository);

  @override
  Future<Either<Failure, Transit>> call(Transit transit) async {
    return await repository.createTransit(transit);
  }
}


