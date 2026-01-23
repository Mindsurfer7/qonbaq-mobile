import 'package:dartz/dartz.dart' hide Order;
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../core/error/failures.dart';
import '../models/order_model.dart';
import '../datasources/order_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/order_remote_datasource_impl.dart';

/// Реализация репозитория заказов
/// Использует Remote DataSource
class OrderRepositoryImpl extends RepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Order>> createOrder(Order order, String businessId) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      final createdOrder = await remoteDataSource.createOrder(orderModel, businessId);
      return Right(createdOrder.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getOrders({
    required String businessId,
    String? customerId,
    OrderFunnelStage? stage,
    bool? isPaid,
    bool? isOverdue,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final orders = await remoteDataSource.getOrders(
        businessId: businessId,
        customerId: customerId,
        stage: stage,
        isPaid: isPaid,
        isOverdue: isOverdue,
        search: search,
        limit: limit,
        offset: offset,
      );
      return Right(orders.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении заказов: $e'));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id, String businessId) async {
    try {
      final order = await remoteDataSource.getOrderById(id, businessId);
      return Right(order.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrder(String id, String businessId, Order order) async {
    try {
      final orderModel = OrderModel.fromEntity(order);
      final updatedOrder = await remoteDataSource.updateOrder(id, businessId, orderModel);
      return Right(updatedOrder.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, Order>> moveOrderStage(
    String id,
    String businessId,
    OrderFunnelStage stage,
    String? returnReason,
  ) async {
    try {
      final order = await remoteDataSource.moveOrderStage(id, businessId, stage, returnReason);
      return Right(order.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при перемещении заказа по воронке: $e'));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrderPayment(
    String id,
    String businessId,
    double paidAmount,
    DateTime? paymentDueDate,
  ) async {
    try {
      final order = await remoteDataSource.updateOrderPayment(id, businessId, paidAmount, paymentDueDate);
      return Right(order.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении оплаты заказа: $e'));
    }
  }

  @override
  Future<Either<Failure, OrderObserver>> addObserver(
    String orderId,
    String userId,
    String businessId,
  ) async {
    try {
      final observer = await remoteDataSource.addObserver(orderId, userId, businessId);
      return Right(observer.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении наблюдателя: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeObserver(
    String orderId,
    String userId,
    String businessId,
  ) async {
    try {
      await remoteDataSource.removeObserver(orderId, userId, businessId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении наблюдателя: $e'));
    }
  }
}
