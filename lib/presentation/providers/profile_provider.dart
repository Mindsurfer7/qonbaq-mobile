import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/get_user_businesses.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием профиля пользователя
class ProfileProvider with ChangeNotifier {
  final GetUserBusinesses getUserBusinesses;
  final GetUserProfile getUserProfile;
  final UserRepository userRepository;

  ProfileProvider({
    required this.getUserBusinesses,
    required this.getUserProfile,
    required this.userRepository,
  });

  List<Business>? _businesses;
  UserProfile? _profile;
  Business? _selectedBusiness;
  Map<String, List<Employee>> _employeesByBusiness =
      {}; // Кэш сотрудников по businessId
  bool _isLoading = false;
  String? _error;

  /// Список компаний
  List<Business>? get businesses => _businesses;

  /// Профиль пользователя
  UserProfile? get profile => _profile;

  /// Выбранная компания
  Business? get selectedBusiness => _selectedBusiness;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Получить список сотрудников для выбранного бизнеса
  List<Employee>? getEmployeesForSelectedBusiness() {
    if (_selectedBusiness == null) return null;
    return _employeesByBusiness[_selectedBusiness!.id];
  }

  /// Получить список сотрудников для конкретного бизнеса
  List<Employee>? getEmployeesForBusiness(String businessId) {
    return _employeesByBusiness[businessId];
  }

  /// Загрузить список компаний
  Future<void> loadBusinesses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getUserBusinesses.call();
    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (businesses) {
        _businesses = businesses;
        if (businesses.isNotEmpty) {
          _selectedBusiness = businesses.first;
          loadProfile();
          // Загружаем сотрудников для выбранного бизнеса
          loadEmployees(_selectedBusiness!.id);
        } else {
          _isLoading = false;
          notifyListeners();
        }
      },
    );
  }

  /// Загрузить профиль пользователя
  Future<void> loadProfile() async {
    if (_selectedBusiness == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getUserProfile.call(
      GetUserProfileParams(businessId: _selectedBusiness!.id),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (profile) {
        _profile = profile;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Выбрать компанию
  void selectBusiness(Business business) {
    if (_selectedBusiness?.id == business.id) return;

    _selectedBusiness = business;
    _profile = null;
    notifyListeners();
    loadProfile();
    // Загружаем сотрудников для выбранного бизнеса
    loadEmployees(business.id);
  }

  /// Загрузить список сотрудников для бизнеса
  Future<void> loadEmployees(String businessId) async {
    // Если уже загружены, не загружаем снова
    if (_employeesByBusiness.containsKey(businessId) &&
        _employeesByBusiness[businessId]!.isNotEmpty) {
      return;
    }

    try {
      final result = await userRepository.getBusinessEmployees(businessId);
      result.fold(
        (failure) {
          // Ошибка загрузки сотрудников не критична, просто не кэшируем
        },
        (employees) {
          _employeesByBusiness[businessId] = employees;
          notifyListeners();
        },
      );
    } catch (e) {
      // Ошибка загрузки сотрудников не критична
    }
  }

  /// Сохранить список сотрудников в кэш (для использования из виджетов)
  void cacheEmployees(String businessId, List<Employee> employees) {
    _employeesByBusiness[businessId] = employees;
    notifyListeners();
  }

  /// Получить сообщение об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
