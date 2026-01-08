import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/income_category.dart';
import '../repositories/financial_repository.dart';

class GetIncomeCategories implements UseCase<List<IncomeCategory>, String> {
  final FinancialRepository repository;

  GetIncomeCategories(this.repository);

  @override
  Future<Either<Failure, List<IncomeCategory>>> call(String businessId) async {
    return await repository.getIncomeCategories(businessId: businessId);
  }
}


