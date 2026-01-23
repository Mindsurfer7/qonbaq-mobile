import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

/// Параметры для получения списка заказов
class GetOrdersParams {
  final String businessId;
  final String? customerId;
  final OrderFunnelStage? stage;
  final bool? isPaid;
  final bool? isOverdue;
  final String? search;
  final int? limit;
  final int? offset;

  GetOrdersParams({
    required this.businessId,
    this.customerId,
    this.stage,
    this.isPaid,
    this.isOverdue,
    this.search,
    this.limit,
    this.offset,
  });
}

/// Use Case для получения списка заказов
class GetOrders implements UseCase<List<Order>, GetOrdersParams> {
  final OrderRepository repository;

  GetOrders(this.repository);

  @override
  Future<Either<Failure, List<Order>>> call(GetOrdersParams params) async {
    return await repository.getOrders(
      businessId: params.businessId,
      customerId: params.customerId,
      stage: params.stage,
      isPaid: params.isPaid,
      isOverdue: params.isOverdue,
      search: params.search,
      limit: params.limit,
      offset: params.offset,
    );
  }
}
