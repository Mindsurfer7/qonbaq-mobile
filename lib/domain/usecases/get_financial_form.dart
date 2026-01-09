import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_template.dart';
import '../repositories/financial_repository.dart';

class GetFinancialForm implements UseCase<ApprovalTemplate, GetFinancialFormParams> {
  final FinancialRepository repository;

  GetFinancialForm(this.repository);

  @override
  Future<Either<Failure, ApprovalTemplate>> call(GetFinancialFormParams params) async {
    switch (params.type) {
      case FinancialFormType.income:
        return await repository.getIncomeForm(businessId: params.businessId);
      case FinancialFormType.expense:
        return await repository.getExpenseForm(businessId: params.businessId);
      case FinancialFormType.transit:
        return await repository.getTransitForm(businessId: params.businessId);
      case FinancialFormType.cashless: // Совместимость со старым кодом
        return await repository.getExpenseForm(businessId: params.businessId);
      case FinancialFormType.cash: // Совместимость со старым кодом
        return await repository.getExpenseForm(businessId: params.businessId);
    }
  }
}

enum FinancialFormType {
  income,
  expense,
  transit,
  cashless, // Legacy
  cash, // Legacy
}

class GetFinancialFormParams {
  final FinancialFormType type;
  final String businessId;

  GetFinancialFormParams({
    required this.type,
    required this.businessId,
  });
}
