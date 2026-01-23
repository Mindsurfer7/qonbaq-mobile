import 'package:dartz/dartz.dart' hide Order;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

/// Параметры для создания заказа
class CreateOrderParams {
  final Order order;
  final String businessId;

  CreateOrderParams({
    required this.order,
    required this.businessId,
  });
}

/// Use Case для создания заказа
class CreateOrder implements UseCase<Order, CreateOrderParams> {
  final OrderRepository repository;

  CreateOrder(this.repository);

  @override
  Future<Either<Failure, Order>> call(CreateOrderParams params) async {
    return await repository.createOrder(params.order, params.businessId);
  }
}
