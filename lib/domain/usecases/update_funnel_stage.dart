import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для обновления стадии воронки продаж
class UpdateFunnelStageParams {
  final String id;
  final String businessId;
  final SalesFunnelStage salesFunnelStage;
  final String? refusalReason;

  UpdateFunnelStageParams({
    required this.id,
    required this.businessId,
    required this.salesFunnelStage,
    this.refusalReason,
  });
}

/// Use Case для обновления стадии воронки продаж
class UpdateFunnelStage implements UseCase<Customer, UpdateFunnelStageParams> {
  final CustomerRepository repository;

  UpdateFunnelStage(this.repository);

  @override
  Future<Either<Failure, Customer>> call(UpdateFunnelStageParams params) async {
    return await repository.updateFunnelStage(
      params.id,
      params.businessId,
      params.salesFunnelStage,
      params.refusalReason,
    );
  }
}
