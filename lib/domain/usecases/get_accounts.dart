import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/account.dart';
import '../repositories/financial_repository.dart';

class GetAccounts implements UseCase<List<Account>, GetAccountsParams> {
  final FinancialRepository repository;

  GetAccounts(this.repository);

  @override
  Future<Either<Failure, List<Account>>> call(GetAccountsParams params) async {
    return await repository.getAccounts(
      businessId: params.businessId,
      projectId: params.projectId,
      accountType: params.accountType,
    );
  }
}

class GetAccountsParams {
  final String businessId;
  final String? projectId;
  final String? accountType;

  GetAccountsParams({
    required this.businessId,
    this.projectId,
    this.accountType,
  });
}
