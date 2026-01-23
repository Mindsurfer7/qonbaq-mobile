import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart' hide Order;
import '../../domain/entities/order.dart';
import '../../domain/usecases/get_orders.dart';
import '../../domain/usecases/create_order.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием заказов (воронка заказов)
class OrdersProvider with ChangeNotifier {
  final GetOrders getOrders;
  final CreateOrder createOrder;

  OrdersProvider({
    required this.getOrders,
    required this.createOrder,
  });

  // Кэш заказов по статусам воронки
  final Map<OrderFunnelStage, List<Order>> _ordersByStage = {};
  
  // Статусы загрузки по статусам
  final Map<OrderFunnelStage, bool> _loadingByStage = {};
  
  // Ошибки по статусам
  final Map<OrderFunnelStage, String?> _errorsByStage = {};
  
  // Общий статус загрузки
  bool _isLoading = false;
  String? _error;
  
  // Последний загруженный businessId
  String? _lastBusinessId;

  /// Получить заказы по статусу воронки
  List<Order> getOrdersByStage(OrderFunnelStage stage) {
    return _ordersByStage[stage] ?? [];
  }

  /// Проверить, загружаются ли заказы для статуса
  bool isLoadingStage(OrderFunnelStage stage) {
    return _loadingByStage[stage] ?? false;
  }

  /// Получить ошибку для статуса
  String? getErrorForStage(OrderFunnelStage stage) {
    return _errorsByStage[stage];
  }

  /// Общий статус загрузки
  bool get isLoading => _isLoading;

  /// Общая ошибка
  String? get error => _error;

  /// Загрузить заказы для всех статусов воронки
  Future<void> loadAllOrders(String businessId) async {
    if (_lastBusinessId == businessId && _ordersByStage.isNotEmpty) {
      // Уже загружены для этого businessId
      return;
    }

    _isLoading = true;
    _error = null;
    _lastBusinessId = businessId;
    notifyListeners();

    // Загружаем заказы для каждого статуса параллельно
    final stages = OrderFunnelStage.values;
    final results = await Future.wait(
      stages.map((stage) => _loadOrdersForStage(businessId, stage)),
    );

    _isLoading = false;
    
    // Проверяем, есть ли ошибки
    final hasErrors = results.any((result) => result.isLeft());
    if (hasErrors) {
      _error = 'Ошибка при загрузке некоторых данных';
    }

    notifyListeners();
  }

  /// Загрузить заказы для конкретного статуса
  Future<void> loadOrdersForStage(String businessId, OrderFunnelStage stage) async {
    await _loadOrdersForStage(businessId, stage);
  }

  /// Внутренний метод загрузки заказов для статуса
  Future<Either<Failure, List<Order>>> _loadOrdersForStage(
    String businessId,
    OrderFunnelStage stage,
  ) async {
    _loadingByStage[stage] = true;
    _errorsByStage[stage] = null;
    notifyListeners();

    final result = await getOrders.call(
      GetOrdersParams(
        businessId: businessId,
        stage: stage,
      ),
    );

    _loadingByStage[stage] = false;

    return result.fold(
      (failure) {
        _errorsByStage[stage] = _getErrorMessage(failure);
        notifyListeners();
        return Left<Failure, List<Order>>(failure);
      },
      (orders) {
        final ordersList = List<Order>.from(orders);
        _ordersByStage[stage] = ordersList;
        _errorsByStage[stage] = null;
        notifyListeners();
        return Right<Failure, List<Order>>(ordersList);
      },
    );
  }

  /// Обновить заказы для конкретного статуса
  Future<void> refreshStage(String businessId, OrderFunnelStage stage) async {
    await _loadOrdersForStage(businessId, stage);
  }

  /// Обновить всех заказов
  Future<void> refreshAll(String businessId) async {
    _ordersByStage.clear();
    _errorsByStage.clear();
    await loadAllOrders(businessId);
  }

  /// Создать заказ
  Future<Either<Failure, Order>> createOrderForBusiness(
    Order order,
    String businessId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createOrder.call(
      CreateOrderParams(
        order: order,
        businessId: businessId,
      ),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return Left(failure);
      },
      (createdOrder) {
        _error = null;
        // Добавляем созданный заказ в кэш соответствующего статуса
        final stage = createdOrder.stage;
        if (_ordersByStage.containsKey(stage)) {
          _ordersByStage[stage] = [..._ordersByStage[stage]!, createdOrder];
        } else {
          _ordersByStage[stage] = [createdOrder];
        }
        notifyListeners();
        return Right(createdOrder);
      },
    );
  }

  /// Очистить кэш
  void clearCache() {
    _ordersByStage.clear();
    _loadingByStage.clear();
    _errorsByStage.clear();
    _error = null;
    _lastBusinessId = null;
    notifyListeners();
  }

  /// Получить сообщение об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is GeneralFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
