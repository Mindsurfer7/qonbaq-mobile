import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/income.dart';
import '../repositories/financial_repository.dart';

class CreateIncome implements UseCase<Income, Income> {
  final FinancialRepository repository;

  CreateIncome(this.repository);

  @override
  Future<Either<Failure, Income>> call(Income income) async {
    return await repository.createIncome(income);
  }
}


