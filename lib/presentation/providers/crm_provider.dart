import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart' hide Order, Task;
import '../../domain/entities/customer.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_customers.dart';
import '../../domain/usecases/get_orders.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/create_customer.dart';
import '../../domain/usecases/create_order.dart';
import '../../core/error/failures.dart';

/// Объединенный провайдер для управления состоянием CRM
/// Включает воронку продаж (customers), воронку заказов (orders) и задачи по клиентам
class CrmProvider with ChangeNotifier {
  final GetCustomers getCustomers;
  final GetOrders getOrders;
  final GetTasks getTasks;
  final CreateCustomer createCustomer;
  final CreateOrder createOrder;

  CrmProvider({
    required this.getCustomers,
    required this.getOrders,
    required this.getTasks,
    required this.createCustomer,
    required this.createOrder,
  });

  // ========== КЛИЕНТЫ (Воронка продаж) ==========
  
  // Кэш клиентов по статусам воронки
  final Map<SalesFunnelStage, List<Customer>> _customersByStage = {};
  
  // Статусы загрузки по статусам
  final Map<SalesFunnelStage, bool> _loadingCustomersByStage = {};
  
  // Ошибки по статусам
  final Map<SalesFunnelStage, String?> _errorsCustomersByStage = {};

  // Общий список клиентов (без фильтра по статусу)
  List<Customer> _allCustomers = [];
  bool _isLoadingAllCustomers = false;
  String? _errorAllCustomers;

  // ========== ЗАКАЗЫ (Воронка заказов) ==========
  
  // Кэш заказов по статусам воронки
  final Map<OrderFunnelStage, List<Order>> _ordersByStage = {};
  
  // Статусы загрузки по статусам
  final Map<OrderFunnelStage, bool> _loadingOrdersByStage = {};
  
  // Ошибки по статусам
  final Map<OrderFunnelStage, String?> _errorsOrdersByStage = {};

  // ========== ЗАДАЧИ ПО КЛИЕНТАМ ==========
  
  List<Task> _customerTasks = [];
  bool _isLoadingCustomerTasks = false;
  String? _errorCustomerTasks;

  // ========== ОБЩИЕ ПОЛЯ ==========
  
  // Последний загруженный businessId
  String? _lastBusinessId;

  // ========== МЕТОДЫ ДЛЯ КЛИЕНТОВ ==========

  /// Получить клиентов по статусу воронки
  List<Customer> getCustomersByStage(SalesFunnelStage stage) {
    return _customersByStage[stage] ?? [];
  }

  /// Получить количество клиентов по статусу
  int getCustomersCountByStage(SalesFunnelStage stage) {
    return _customersByStage[stage]?.length ?? 0;
  }

  /// Проверить, загружаются ли клиенты для статуса
  bool isLoadingCustomersStage(SalesFunnelStage stage) {
    return _loadingCustomersByStage[stage] ?? false;
  }

  /// Получить ошибку для статуса клиентов
  String? getErrorForCustomersStage(SalesFunnelStage stage) {
    return _errorsCustomersByStage[stage];
  }

  /// Получить всех клиентов (без фильтра по статусу)
  List<Customer> get allCustomers => _allCustomers;

  /// Проверить, загружаются ли все клиенты
  bool get isLoadingAllCustomers => _isLoadingAllCustomers;

  /// Получить ошибку для всех клиентов
  String? get errorAllCustomers => _errorAllCustomers;

  /// Загрузить клиентов для всех статусов воронки
  Future<void> loadAllCustomers(String businessId) async {
    if (_lastBusinessId == businessId && _customersByStage.isNotEmpty) {
      // Уже загружены для этого businessId
      return;
    }

    _lastBusinessId = businessId;

    // Загружаем клиентов для каждого статуса параллельно
    final stages = SalesFunnelStage.values;
    await Future.wait(
      stages.map((stage) => _loadCustomersForStage(businessId, stage)),
    );
  }

  /// Загрузить клиентов для конкретного статуса
  Future<void> loadCustomersForStage(String businessId, SalesFunnelStage stage) async {
    await _loadCustomersForStage(businessId, stage);
  }

  /// Внутренний метод загрузки клиентов для статуса
  Future<Either<Failure, List<Customer>>> _loadCustomersForStage(
    String businessId,
    SalesFunnelStage stage,
  ) async {
    _loadingCustomersByStage[stage] = true;
    _errorsCustomersByStage[stage] = null;
    notifyListeners();

    final result = await getCustomers.call(
      GetCustomersParams(
        businessId: businessId,
        salesFunnelStage: stage,
      ),
    );

    _loadingCustomersByStage[stage] = false;

    return result.fold(
      (failure) {
        _errorsCustomersByStage[stage] = _getErrorMessage(failure);
        notifyListeners();
        return Left(failure);
      },
      (customers) {
        _customersByStage[stage] = customers;
        _errorsCustomersByStage[stage] = null;
        notifyListeners();
        return Right(customers);
      },
    );
  }

  /// Загрузить всех клиентов (без фильтра по статусу)
  Future<void> loadAllCustomersList(String businessId) async {
    _isLoadingAllCustomers = true;
    _errorAllCustomers = null;
    notifyListeners();

    // Загружаем всех клиентов без фильтра по статусу
    final result = await getCustomers.call(
      GetCustomersParams(
        businessId: businessId,
      ),
    );

    _isLoadingAllCustomers = false;

    result.fold(
      (failure) {
        _errorAllCustomers = _getErrorMessage(failure);
        notifyListeners();
      },
      (customers) {
        _allCustomers = customers;
        _errorAllCustomers = null;
        notifyListeners();
      },
    );
  }

  /// Обновить клиентов для конкретного статуса
  Future<void> refreshCustomersStage(String businessId, SalesFunnelStage stage) async {
    await _loadCustomersForStage(businessId, stage);
  }

  /// Обновить всех клиентов
  Future<void> refreshAllCustomers(String businessId) async {
    _customersByStage.clear();
    _errorsCustomersByStage.clear();
    await loadAllCustomers(businessId);
  }

  /// Обновить всех клиентов (старый метод для совместимости)
  @Deprecated('Используйте refreshAllCustomers')
  Future<void> refreshAll(String businessId) async {
    await refreshAllCustomers(businessId);
  }

  /// Старый метод для совместимости
  @Deprecated('Используйте isLoadingCustomersStage')
  bool isLoadingStage(SalesFunnelStage stage) {
    return isLoadingCustomersStage(stage);
  }

  /// Старый метод для совместимости
  @Deprecated('Используйте getErrorForCustomersStage')
  String? getErrorForStage(SalesFunnelStage stage) {
    return getErrorForCustomersStage(stage);
  }

  /// Старый метод для совместимости
  @Deprecated('Используйте isLoading')
  bool get isLoading {
    return _loadingCustomersByStage.values.any((loading) => loading) ||
           _loadingOrdersByStage.values.any((loading) => loading) ||
           _isLoadingAllCustomers ||
           _isLoadingCustomerTasks;
  }

  /// Создать клиента
  Future<Either<Failure, Customer>> createCustomerForBusiness(
    Customer customer,
    String businessId,
  ) async {
    final result = await createCustomer.call(customer);

    return result.fold(
      (failure) => Left(failure),
      (createdCustomer) {
        // Добавляем созданного клиента в кэш соответствующего статуса
        final stage = createdCustomer.salesFunnelStage ?? SalesFunnelStage.unprocessed;
        if (_customersByStage.containsKey(stage)) {
          _customersByStage[stage] = [..._customersByStage[stage]!, createdCustomer];
        } else {
          _customersByStage[stage] = [createdCustomer];
        }
        notifyListeners();
        return Right(createdCustomer);
      },
    );
  }

  // ========== МЕТОДЫ ДЛЯ ЗАКАЗОВ ==========

  /// Получить заказы по статусу воронки
  List<Order> getOrdersByStage(OrderFunnelStage stage) {
    return _ordersByStage[stage] ?? [];
  }

  /// Получить количество заказов по статусу
  int getOrdersCountByStage(OrderFunnelStage stage) {
    return _ordersByStage[stage]?.length ?? 0;
  }

  /// Проверить, загружаются ли заказы для статуса
  bool isLoadingOrdersStage(OrderFunnelStage stage) {
    return _loadingOrdersByStage[stage] ?? false;
  }

  /// Получить ошибку для статуса заказов
  String? getErrorForOrdersStage(OrderFunnelStage stage) {
    return _errorsOrdersByStage[stage];
  }

  /// Загрузить заказы для всех статусов воронки
  Future<void> loadAllOrders(String businessId) async {
    if (_lastBusinessId == businessId && _ordersByStage.isNotEmpty) {
      // Уже загружены для этого businessId
      return;
    }

    _lastBusinessId = businessId;

    // Загружаем заказы для каждого статуса параллельно
    final stages = OrderFunnelStage.values;
    await Future.wait(
      stages.map((stage) => _loadOrdersForStage(businessId, stage)),
    );
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
    _loadingOrdersByStage[stage] = true;
    _errorsOrdersByStage[stage] = null;
    notifyListeners();

    final result = await getOrders.call(
      GetOrdersParams(
        businessId: businessId,
        stage: stage,
      ),
    );

    _loadingOrdersByStage[stage] = false;

    return result.fold(
      (failure) {
        _errorsOrdersByStage[stage] = _getErrorMessage(failure);
        notifyListeners();
        return Left<Failure, List<Order>>(failure);
      },
      (orders) {
        final ordersList = List<Order>.from(orders);
        _ordersByStage[stage] = ordersList;
        _errorsOrdersByStage[stage] = null;
        notifyListeners();
        return Right<Failure, List<Order>>(ordersList);
      },
    );
  }

  /// Обновить заказы для конкретного статуса
  Future<void> refreshOrdersStage(String businessId, OrderFunnelStage stage) async {
    await _loadOrdersForStage(businessId, stage);
  }

  /// Обновить всех заказов
  Future<void> refreshAllOrders(String businessId) async {
    _ordersByStage.clear();
    _errorsOrdersByStage.clear();
    await loadAllOrders(businessId);
  }

  /// Создать заказ
  Future<Either<Failure, Order>> createOrderForBusiness(
    Order order,
    String businessId,
  ) async {
    final result = await createOrder.call(
      CreateOrderParams(
        order: order,
        businessId: businessId,
      ),
    );

    return result.fold(
      (failure) => Left(failure),
      (createdOrder) {
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

  // ========== МЕТОДЫ ДЛЯ ЗАДАЧ ==========

  /// Получить задачи по клиентам
  List<Task> get customerTasks => _customerTasks;

  /// Получить количество задач по клиентам
  int get customerTasksCount => _customerTasks.length;

  /// Проверить, загружаются ли задачи
  bool get isLoadingCustomerTasks => _isLoadingCustomerTasks;

  /// Получить ошибку для задач
  String? get errorCustomerTasks => _errorCustomerTasks;

  /// Загрузить задачи по клиентам
  Future<void> loadCustomerTasks(String businessId) async {
    _isLoadingCustomerTasks = true;
    _errorCustomerTasks = null;
    notifyListeners();

    final result = await getTasks.call(
      GetTasksParams(
        businessId: businessId,
        hasCustomer: true, // Только задачи с клиентами
        limit: 100,
      ),
    );

    _isLoadingCustomerTasks = false;

    result.fold(
      (failure) {
        _errorCustomerTasks = _getErrorMessage(failure);
        notifyListeners();
      },
      (tasks) {
        _customerTasks = tasks;
        _errorCustomerTasks = null;
        notifyListeners();
      },
    );
  }

  /// Обновить задачи по клиентам
  Future<void> refreshCustomerTasks(String businessId) async {
    await loadCustomerTasks(businessId);
  }

  // ========== ОБЩИЕ МЕТОДЫ ==========

  /// Загрузить все данные CRM
  Future<void> loadAllCrmData(String businessId) async {
    _lastBusinessId = businessId;
    
    // Загружаем все данные параллельно
    await Future.wait([
      loadAllCustomers(businessId),
      loadAllOrders(businessId),
      loadCustomerTasks(businessId),
      loadAllCustomersList(businessId),
    ]);
  }

  /// Обновить все данные CRM
  Future<void> refreshAllCrmData(String businessId) async {
    _customersByStage.clear();
    _errorsCustomersByStage.clear();
    _ordersByStage.clear();
    _errorsOrdersByStage.clear();
    _customerTasks.clear();
    await loadAllCrmData(businessId);
  }

  /// Очистить кэш
  void clearCache() {
    _customersByStage.clear();
    _loadingCustomersByStage.clear();
    _errorsCustomersByStage.clear();
    _allCustomers.clear();
    _ordersByStage.clear();
    _loadingOrdersByStage.clear();
    _errorsOrdersByStage.clear();
    _customerTasks.clear();
    _errorAllCustomers = null;
    _errorCustomerTasks = null;
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
