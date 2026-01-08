import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/account.dart';
import '../repositories/financial_repository.dart';

/// Параметры для создания счета
class CreateAccountParams {
  final Account account;

  CreateAccountParams({required this.account});
}

/// Use Case для создания счета
class CreateAccount implements UseCase<Account, CreateAccountParams> {
  final FinancialRepository repository;

  CreateAccount(this.repository);

  @override
  Future<Either<Failure, Account>> call(CreateAccountParams params) async {
    return await repository.createAccount(params.account);
  }
}


