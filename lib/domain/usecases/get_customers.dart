import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/customer.dart';
import '../repositories/customer_repository.dart';

/// Параметры для получения списка клиентов
class GetCustomersParams {
  final String businessId;
  final SalesFunnelStage? salesFunnelStage;
  final String? responsibleId;
  final String? search;
  final bool? showAll;
  final int? limit;
  final int? offset;

  GetCustomersParams({
    required this.businessId,
    this.salesFunnelStage,
    this.responsibleId,
    this.search,
    this.showAll,
    this.limit,
    this.offset,
  });
}

/// Use Case для получения списка клиентов
class GetCustomers implements UseCase<List<Customer>, GetCustomersParams> {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(GetCustomersParams params) async {
    return await repository.getCustomers(
      businessId: params.businessId,
      salesFunnelStage: params.salesFunnelStage,
      responsibleId: params.responsibleId,
      search: params.search,
      showAll: params.showAll,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
