import '../datasources/datasource.dart';
import '../../domain/entities/order.dart';
import '../models/order_model.dart';
import '../models/order_observer_model.dart';

/// Удаленный источник данных для заказов (API)
abstract class OrderRemoteDataSource extends DataSource {
  /// Создать заказ
  Future<OrderModel> createOrder(OrderModel order, String businessId);

  /// Получить список заказов
  Future<List<OrderModel>> getOrders({
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
  Future<OrderModel> getOrderById(String id, String businessId);

  /// Обновить заказ
  Future<OrderModel> updateOrder(String id, String businessId, OrderModel order);

  /// Переместить заказ по воронке
  Future<OrderModel> moveOrderStage(
    String id,
    String businessId,
    OrderFunnelStage stage,
    String? returnReason,
  );

  /// Обновить оплату заказа
  Future<OrderModel> updateOrderPayment(
    String id,
    String businessId,
    double paidAmount,
    DateTime? paymentDueDate,
  );

  /// Добавить наблюдателя за заказом
  Future<OrderObserverModel> addObserver(
    String orderId,
    String userId,
    String businessId,
  );

  /// Удалить наблюдателя за заказом
  Future<void> removeObserver(
    String orderId,
    String userId,
    String businessId,
  );
}
