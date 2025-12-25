import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_template.dart';
import '../repositories/financial_repository.dart';

/// Тип финансовой формы
enum FinancialFormType {
  cashless, // Безналичная оплата
  cash, // Наличная оплата
}

/// Параметры для получения финансовой формы
class GetFinancialFormParams {
  final FinancialFormType type;
  final String businessId;

  GetFinancialFormParams({
    required this.type,
    required this.businessId,
  });
}

/// Use Case для получения финансовой формы
class GetFinancialForm implements UseCase<ApprovalTemplate, GetFinancialFormParams> {
  final FinancialRepository repository;

  GetFinancialForm(this.repository);

  @override
  Future<Either<Failure, ApprovalTemplate>> call(GetFinancialFormParams params) async {
    switch (params.type) {
      case FinancialFormType.cashless:
        return await repository.getCashlessForm(businessId: params.businessId);
      case FinancialFormType.cash:
        return await repository.getCashForm(businessId: params.businessId);
    }
  }
}

