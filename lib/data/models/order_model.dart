import '../../domain/entities/order.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/business.dart';
import '../models/model.dart';
import 'customer_model.dart';
import 'business_model.dart';
import 'order_observer_model.dart';

/// Модель заказа
class OrderModel extends Order implements Model {
  const OrderModel({
    required super.id,
    required super.businessId,
    required super.customerId,
    required super.stage,
    super.orderNumber,
    super.description,
    super.returnReason,
    required super.totalAmount,
    required super.paidAmount,
    required super.isPaid,
    required super.isPartiallyPaid,
    required super.isOverdue,
    super.paymentDueDate,
    super.overdueDate,
    super.lastPaymentDate,
    required super.isBlocked,
    super.blockedReason,
    required super.movedAt,
    super.movedBy,
    super.mover,
    required super.createdAt,
    required super.updatedAt,
    super.customer,
    super.observers,
    super.business,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Парсинг mover
    User? mover;
    if (json['mover'] != null) {
      final moverJson = json['mover'] as Map<String, dynamic>;
      final email = moverJson['email'] as String?;
      if (email != null) {
        mover = User(
          id: moverJson['id'] as String,
          name: moverJson['firstName'] != null && moverJson['lastName'] != null
              ? '${moverJson['firstName']} ${moverJson['lastName']}'
              : email,
          email: email,
        );
      }
    }

    // Парсинг customer
    Customer? customer;
    if (json['customer'] != null) {
      customer = CustomerModel.fromJson(json['customer'] as Map<String, dynamic>).toEntity();
    }

    // Парсинг observers
    List<OrderObserver>? observers;
    if (json['observers'] != null) {
      final observersList = json['observers'] as List<dynamic>;
      observers = observersList
          .map((observerJson) => OrderObserverModel.fromJson(observerJson as Map<String, dynamic>).toEntity())
          .toList();
    }

    // Парсинг business
    Business? business;
    if (json['business'] != null) {
      business = BusinessModel.fromJson(json['business'] as Map<String, dynamic>).toEntity();
    }

    // Парсинг orderNumber - может быть числом или строкой
    String? orderNumber;
    if (json['orderNumber'] != null) {
      orderNumber = json['orderNumber'].toString();
    }

    return OrderModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      customerId: json['customerId'] as String,
      stage: _parseOrderFunnelStage(json['stage'] as String),
      orderNumber: orderNumber,
      description: json['description'] as String?,
      returnReason: json['returnReason'] as String?,
      totalAmount: _parseAmount(json['totalAmount']),
      paidAmount: _parseAmount(json['paidAmount']),
      isPaid: json['isPaid'] as bool,
      isPartiallyPaid: json['isPartiallyPaid'] as bool,
      isOverdue: json['isOverdue'] as bool,
      paymentDueDate: json['paymentDueDate'] != null
          ? DateTime.parse(json['paymentDueDate'] as String)
          : null,
      overdueDate: json['overdueDate'] != null
          ? DateTime.parse(json['overdueDate'] as String)
          : null,
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.parse(json['lastPaymentDate'] as String)
          : null,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedReason: json['blockedReason'] as String?,
      movedAt: json['movedAt'] != null
          ? DateTime.parse(json['movedAt'] as String)
          : DateTime.now(),
      movedBy: json['movedBy'] as String?,
      mover: mover,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      customer: customer,
      observers: observers,
      business: business,
    );
  }

  /// Парсинг суммы - может быть строкой или числом
  static double _parseAmount(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static OrderFunnelStage _parseOrderFunnelStage(String stage) {
    switch (stage.toUpperCase()) {
      case 'ORDER_ACCEPTED':
        return OrderFunnelStage.orderAccepted;
      case 'ORDER_STARTED':
        return OrderFunnelStage.orderStarted;
      case 'ORDER_IN_PROGRESS':
        return OrderFunnelStage.orderInProgress;
      case 'ORDER_READY':
        return OrderFunnelStage.orderReady;
      case 'ORDER_DELIVERED':
        return OrderFunnelStage.orderDelivered;
      case 'ORDER_RETURNED':
        return OrderFunnelStage.orderReturned;
      default:
        return OrderFunnelStage.orderAccepted;
    }
  }

  static String _orderFunnelStageToString(OrderFunnelStage stage) {
    switch (stage) {
      case OrderFunnelStage.orderAccepted:
        return 'ORDER_ACCEPTED';
      case OrderFunnelStage.orderStarted:
        return 'ORDER_STARTED';
      case OrderFunnelStage.orderInProgress:
        return 'ORDER_IN_PROGRESS';
      case OrderFunnelStage.orderReady:
        return 'ORDER_READY';
      case OrderFunnelStage.orderDelivered:
        return 'ORDER_DELIVERED';
      case OrderFunnelStage.orderReturned:
        return 'ORDER_RETURNED';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'stage': _orderFunnelStageToString(stage),
      if (orderNumber != null) 'orderNumber': orderNumber,
      if (description != null) 'description': description,
      if (returnReason != null) 'returnReason': returnReason,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'isPaid': isPaid,
      'isPartiallyPaid': isPartiallyPaid,
      'isOverdue': isOverdue,
      if (paymentDueDate != null) 'paymentDueDate': paymentDueDate!.toIso8601String(),
      if (overdueDate != null) 'overdueDate': overdueDate!.toIso8601String(),
      if (lastPaymentDate != null) 'lastPaymentDate': lastPaymentDate!.toIso8601String(),
      'isBlocked': isBlocked,
      if (blockedReason != null) 'blockedReason': blockedReason,
      'movedAt': movedAt.toIso8601String(),
      if (movedBy != null) 'movedBy': movedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания заказа
  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      'customerId': customerId,
      'stage': _orderFunnelStageToString(stage),
      if (orderNumber != null && orderNumber!.isNotEmpty) 'orderNumber': orderNumber,
      if (description != null && description!.isNotEmpty) 'description': description,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'isPaid': isPaid,
      'isPartiallyPaid': isPartiallyPaid,
      'isOverdue': isOverdue,
      if (paymentDueDate != null) 'paymentDueDate': paymentDueDate!.toIso8601String(),
      'isBlocked': isBlocked,
      if (blockedReason != null && blockedReason!.isNotEmpty) 'blockedReason': blockedReason,
    };
  }

  /// Преобразование в JSON для обновления заказа
  Map<String, dynamic> toUpdateJson() {
    return {
      if (orderNumber != null && orderNumber!.isNotEmpty) 'orderNumber': orderNumber,
      if (description != null && description!.isNotEmpty) 'description': description,
      'totalAmount': totalAmount,
      'isBlocked': isBlocked,
      if (blockedReason != null && blockedReason!.isNotEmpty) 'blockedReason': blockedReason,
    };
  }

  Order toEntity() {
    return Order(
      id: id,
      businessId: businessId,
      customerId: customerId,
      stage: stage,
      orderNumber: orderNumber,
      description: description,
      returnReason: returnReason,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      isPaid: isPaid,
      isPartiallyPaid: isPartiallyPaid,
      isOverdue: isOverdue,
      paymentDueDate: paymentDueDate,
      overdueDate: overdueDate,
      lastPaymentDate: lastPaymentDate,
      isBlocked: isBlocked,
      blockedReason: blockedReason,
      movedAt: movedAt,
      movedBy: movedBy,
      mover: mover,
      createdAt: createdAt,
      updatedAt: updatedAt,
      customer: customer,
      observers: observers,
      business: business,
    );
  }

  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      businessId: order.businessId,
      customerId: order.customerId,
      stage: order.stage,
      orderNumber: order.orderNumber,
      description: order.description,
      returnReason: order.returnReason,
      totalAmount: order.totalAmount,
      paidAmount: order.paidAmount,
      isPaid: order.isPaid,
      isPartiallyPaid: order.isPartiallyPaid,
      isOverdue: order.isOverdue,
      paymentDueDate: order.paymentDueDate,
      overdueDate: order.overdueDate,
      lastPaymentDate: order.lastPaymentDate,
      isBlocked: order.isBlocked,
      blockedReason: order.blockedReason,
      movedAt: order.movedAt,
      movedBy: order.movedBy,
      mover: order.mover,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      customer: order.customer,
      observers: order.observers,
      business: order.business,
    );
  }
}
