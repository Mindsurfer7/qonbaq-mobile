import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/expense.dart';
import '../repositories/financial_repository.dart';

class CreateExpense implements UseCase<Expense, Expense> {
  final FinancialRepository repository;

  CreateExpense(this.repository);

  @override
  Future<Either<Failure, Expense>> call(Expense expense) async {
    return await repository.createExpense(expense);
  }
}

