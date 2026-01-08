import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/financial_report.dart';
import '../repositories/financial_repository.dart';

class GetFinancialReport
    implements UseCase<FinancialReport, GetFinancialReportParams> {
  final FinancialRepository repository;

  GetFinancialReport(this.repository);

  @override
  Future<Either<Failure, FinancialReport>> call(
    GetFinancialReportParams params,
  ) async {
    return await repository.getFinancialReport(
      businessId: params.businessId,
      startDate: params.startDate,
      endDate: params.endDate,
      projectId: params.projectId,
      accountId: params.accountId,
    );
  }
}

class GetFinancialReportParams {
  final String businessId;
  final DateTime startDate;
  final DateTime endDate;
  final String? projectId;
  final String? accountId;

  GetFinancialReportParams({
    required this.businessId,
    required this.startDate,
    required this.endDate,
    this.projectId,
    this.accountId,
  });
}
