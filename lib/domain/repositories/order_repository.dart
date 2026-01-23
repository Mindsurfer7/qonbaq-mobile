import 'package:dartz/dartz.dart' hide Order;
import '../entities/order.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с заказами
/// Реализация находится в data слое
abstract class OrderRepository extends Repository {
  /// Создать заказ
  Future<Either<Failure, Order>> createOrder(Order order, String businessId);

  /// Получить список заказов
  Future<Either<Failure, List<Order>>> getOrders({
    required String businessId,
    String? customerId,
    OrderFunnelStage? stage,
    bool? isPaid,
    bool? isOverdue,
    String? search,
    int? limit,
    int? offset,
  });

  /// Получить заказ по ID
  Future<Either<Failure, Order>> getOrderById(String id, String businessId);

  /// Обновить заказ
  Future<Either<Failure, Order>> updateOrder(String id, String businessId, Order order);

  /// Переместить заказ по воронке
  Future<Either<Failure, Order>> moveOrderStage(
    String id,
    String businessId,
    OrderFunnelStage stage,
    String? returnReason,
  );

  /// Обновить оплату заказа
  Future<Either<Failure, Order>> updateOrderPayment(
    String id,
    String businessId,
    double paidAmount,
    DateTime? paymentDueDate,
  );

  /// Добавить наблюдателя за заказом
  Future<Either<Failure, OrderObserver>> addObserver(
    String orderId,
    String userId,
    String businessId,
  );

  /// Удалить наблюдателя за заказом
  Future<Either<Failure, void>> removeObserver(
    String orderId,
    String userId,
    String businessId,
  );
}
