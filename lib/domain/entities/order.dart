import '../entities/entity.dart';
import 'user.dart';
import 'customer.dart';
import 'business.dart';

/// Стадия воронки заказов
enum OrderFunnelStage {
  orderAccepted, // ORDER_ACCEPTED - Заказ принят
  orderStarted, // ORDER_STARTED - Заказ начат
  orderInProgress, // ORDER_IN_PROGRESS - Заказ в работе
  orderReady, // ORDER_READY - Заказ готов
  orderDelivered, // ORDER_DELIVERED - Заказ передан клиенту
  orderReturned, // ORDER_RETURNED - Возврат по причине
}

/// Наблюдатель за заказом
class OrderObserver {
  final String id;
  final String orderId;
  final String userId;
  final DateTime createdAt;
  final User? user;

  const OrderObserver({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.createdAt,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderObserver &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderObserver(id: $id, orderId: $orderId, userId: $userId)';
}

/// Доменная сущность заказа
class Order extends Entity {
  final String id;
  final String businessId;
  final String customerId;
  final OrderFunnelStage stage;

  // Основная информация
  final String? orderNumber;
  final String? description;
  final String? returnReason; // Причина возврата (если стадия = ORDER_RETURNED)

  // Оплата
  final double totalAmount;
  final double paidAmount;
  final bool isPaid;
  final bool isPartiallyPaid;
  final bool isOverdue;
  final DateTime? paymentDueDate;
  final DateTime? overdueDate;
  final DateTime? lastPaymentDate;

  // Блокировки
  final bool isBlocked;
  final String? blockedReason;

  // Перемещение по воронке
  final DateTime movedAt;
  final String? movedBy; // UUID пользователя, который переместил
  final User? mover; // Объект пользователя, который переместил

  // Даты
  final DateTime createdAt;
  final DateTime updatedAt;

  // Связи
  final Customer? customer;
  final List<OrderObserver>? observers;
  final Business? business;

  const Order({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.stage,
    this.orderNumber,
    this.description,
    this.returnReason,
    required this.totalAmount,
    required this.paidAmount,
    required this.isPaid,
    required this.isPartiallyPaid,
    required this.isOverdue,
    this.paymentDueDate,
    this.overdueDate,
    this.lastPaymentDate,
    required this.isBlocked,
    this.blockedReason,
    required this.movedAt,
    this.movedBy,
    this.mover,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.observers,
    this.business,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Order(id: $id, orderNumber: $orderNumber, stage: $stage)';
}
