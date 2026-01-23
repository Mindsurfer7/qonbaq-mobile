import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/get_customers.dart';
import '../../domain/usecases/create_customer.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием CRM (клиенты, воронка продаж)
class CrmProvider with ChangeNotifier {
  final GetCustomers getCustomers;
  final CreateCustomer createCustomer;

  CrmProvider({
    required this.getCustomers,
    required this.createCustomer,
  });

  // Кэш клиентов по статусам воронки
  final Map<SalesFunnelStage, List<Customer>> _customersByStage = {};
  
  // Статусы загрузки по статусам
  final Map<SalesFunnelStage, bool> _loadingByStage = {};
  
  // Ошибки по статусам
  final Map<SalesFunnelStage, String?> _errorsByStage = {};
  
  // Общий статус загрузки
  bool _isLoading = false;
  String? _error;
  
  // Последний загруженный businessId
  String? _lastBusinessId;

  /// Получить клиентов по статусу воронки
  List<Customer> getCustomersByStage(SalesFunnelStage stage) {
    return _customersByStage[stage] ?? [];
  }

  /// Проверить, загружаются ли клиенты для статуса
  bool isLoadingStage(SalesFunnelStage stage) {
    return _loadingByStage[stage] ?? false;
  }

  /// Получить ошибку для статуса
  String? getErrorForStage(SalesFunnelStage stage) {
    return _errorsByStage[stage];
  }

  /// Общий статус загрузки
  bool get isLoading => _isLoading;

  /// Общая ошибка
  String? get error => _error;

  /// Загрузить клиентов для всех статусов воронки
  Future<void> loadAllCustomers(String businessId) async {
    if (_lastBusinessId == businessId && _customersByStage.isNotEmpty) {
      // Уже загружены для этого businessId
      return;
    }

    _isLoading = true;
    _error = null;
    _lastBusinessId = businessId;
    notifyListeners();

    // Загружаем клиентов для каждого статуса параллельно
    final stages = SalesFunnelStage.values;
    final results = await Future.wait(
      stages.map((stage) => _loadCustomersForStage(businessId, stage)),
    );

    _isLoading = false;
    
    // Проверяем, есть ли ошибки
    final hasErrors = results.any((result) => result.isLeft());
    if (hasErrors) {
      _error = 'Ошибка при загрузке некоторых данных';
    }

    notifyListeners();
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
    _loadingByStage[stage] = true;
    _errorsByStage[stage] = null;
    notifyListeners();

    final result = await getCustomers.call(
      GetCustomersParams(
        businessId: businessId,
        salesFunnelStage: stage,
      ),
    );

    _loadingByStage[stage] = false;

    return result.fold(
      (failure) {
        _errorsByStage[stage] = _getErrorMessage(failure);
        notifyListeners();
        return Left(failure);
      },
      (customers) {
        _customersByStage[stage] = customers;
        _errorsByStage[stage] = null;
        notifyListeners();
        return Right(customers);
      },
    );
  }

  /// Обновить клиентов для конкретного статуса
  Future<void> refreshStage(String businessId, SalesFunnelStage stage) async {
    await _loadCustomersForStage(businessId, stage);
  }

  /// Обновить всех клиентов
  Future<void> refreshAll(String businessId) async {
    _customersByStage.clear();
    _errorsByStage.clear();
    await loadAllCustomers(businessId);
  }

  /// Создать клиента
  Future<Either<Failure, Customer>> createCustomerForBusiness(
    Customer customer,
    String businessId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createCustomer.call(customer);

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return Left(failure);
      },
      (createdCustomer) {
        _error = null;
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

  /// Очистить кэш
  void clearCache() {
    _customersByStage.clear();
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
