import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/employment_with_role.dart';
import '../../domain/usecases/get_user_businesses.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/create_business.dart';
import '../../domain/usecases/update_business.dart';
import '../../domain/usecases/get_business_employments_with_roles.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../core/utils/workspace_storage.dart';

/// Провайдер для управления состоянием профиля пользователя
class ProfileProvider with ChangeNotifier {
  final GetUserBusinesses getUserBusinesses;
  final GetUserProfile getUserProfile;
  final CreateBusiness createBusiness;
  final UpdateBusiness updateBusiness;
  final UserRepository userRepository;
  final GetBusinessEmploymentsWithRoles getBusinessEmploymentsWithRoles;
  final String? currentUserId; // ID текущего пользователя для поиска его employment

  ProfileProvider({
    required this.getUserBusinesses,
    required this.getUserProfile,
    required this.createBusiness,
    required this.updateBusiness,
    required this.userRepository,
    required this.getBusinessEmploymentsWithRoles,
    this.currentUserId,
  });

  List<Business>? _businesses;
  UserProfile? _profile;
  Business? _selectedBusiness;
  Business? _selectedWorkspace; // Выбранный workspace (семья или бизнес)
  Map<String, List<Employee>> _employeesByBusiness =
      {}; // Кэш сотрудников по businessId
  EmploymentWithRole? _currentUserEmployment; // Employment текущего пользователя в выбранном бизнесе
  bool _isLoading = false;
  String? _error;

  /// Список компаний
  List<Business>? get businesses => _businesses;

  /// Профиль пользователя
  UserProfile? get profile => _profile;

  /// Выбранная компания
  Business? get selectedBusiness => _selectedBusiness;

  /// Выбранный workspace (семья или бизнес)
  Business? get selectedWorkspace => _selectedWorkspace;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Employment текущего пользователя в выбранном бизнесе
  EmploymentWithRole? get currentUserEmployment => _currentUserEmployment;

  /// Код роли текущего пользователя в выбранном бизнесе
  String? get currentUserRoleCode => _currentUserEmployment?.roleCode;

  /// Проверка, является ли пользователь бухгалтером в текущем бизнесе
  bool get isAccountant => currentUserRoleCode == 'ACCOUNTANT';

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
        _isLoading = false;
        notifyListeners();

        // Пытаемся загрузить сохраненный workspace
        _loadSavedWorkspace(businesses).then((_) {
          // Если workspace не был загружен, но есть бизнесы,
          // не выбираем автоматически - пользователь должен выбрать сам
        });
      },
    );
  }

  /// Загрузить сохраненный workspace из локального хранилища
  Future<void> _loadSavedWorkspace(List<Business> businesses) async {
    if (businesses.isEmpty) return;

    final savedWorkspaceId = await WorkspaceStorage.getSelectedWorkspaceId();
    if (savedWorkspaceId != null) {
      try {
        final savedBusiness = businesses.firstWhere(
          (b) => b.id == savedWorkspaceId,
        );
        // Устанавливаем workspace без сохранения (он уже сохранен)
        _selectedWorkspace = savedBusiness;
        _selectedBusiness = savedBusiness;
        loadProfile();
        loadEmployees(savedBusiness.id);
        notifyListeners();
      } catch (e) {
        // Если сохраненный workspace не найден в списке, очищаем сохранение
        await WorkspaceStorage.clearSelectedWorkspaceId();
      }
    }
  }

  /// Получить бизнес семьи (бизнес с типом Family)
  Business? get familyBusiness {
    if (_businesses == null || _businesses!.isEmpty) return null;
    try {
      return _businesses!.firstWhere((b) => b.type == BusinessType.family);
    } catch (e) {
      return null;
    }
  }

  /// Получить список бизнесов (только с типом Business или без типа)
  List<Business> get businessList {
    if (_businesses == null || _businesses!.isEmpty) return [];
    return _businesses!
        .where((b) => b.type == null || b.type == BusinessType.business)
        .toList();
  }

  /// Установить ID текущего пользователя (вызывается при авторизации)
  void setCurrentUserId(String userId) {
    // Обновляем currentUserId динамически
    // Это будет использоваться для загрузки employment
  }

  /// Загрузить профиль пользователя
  Future<void> loadProfile({String? userId}) async {
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
        
        // Загружаем employment текущего пользователя
        // Используем userId из параметра или из профиля
        final userIdToUse = userId ?? currentUserId ?? profile.user.id;
        loadCurrentUserEmployment(_selectedBusiness!.id, userIdToUse);
      },
    );
  }

  /// Загрузить employment текущего пользователя для бизнеса
  Future<void> loadCurrentUserEmployment(String businessId, String userId) async {
    try {
      final result = await getBusinessEmploymentsWithRoles.call(
        GetBusinessEmploymentsWithRolesParams(businessId: businessId),
      );

      result.fold(
        (failure) {
          // Ошибка не критична, просто не сохраняем employment
          _currentUserEmployment = null;
        },
        (employments) {
          // Находим employment текущего пользователя
          try {
            _currentUserEmployment = employments.firstWhere(
              (emp) => emp.userId == userId,
            );
          } catch (e) {
            // Пользователь не найден в списке сотрудников
            _currentUserEmployment = null;
          }
          notifyListeners();
        },
      );
    } catch (e) {
      // Ошибка не критична
      _currentUserEmployment = null;
    }
  }

  /// Выбрать компанию
  void selectBusiness(Business business) {
    if (_selectedBusiness?.id == business.id) return;

    _selectedBusiness = business;
    _profile = null;
    _currentUserEmployment = null; // Сбрасываем employment при смене бизнеса
    notifyListeners();
    loadProfile();
    // Загружаем сотрудников для выбранного бизнеса
    loadEmployees(business.id);
  }

  /// Выбрать workspace (семья или бизнес)
  Future<void> selectWorkspace(Business workspace) async {
    if (_selectedWorkspace?.id == workspace.id) return;

    _selectedWorkspace = workspace;
    _selectedBusiness = workspace;
    _profile = null;
    _currentUserEmployment = null; // Сбрасываем employment при смене workspace

    // Сохраняем выбранный workspace в локальное хранилище
    await WorkspaceStorage.saveSelectedWorkspaceId(workspace.id);

    notifyListeners();
    loadProfile();
    // Загружаем сотрудников для выбранного workspace
    loadEmployees(workspace.id);
  }

  /// Очистить выбранный workspace
  Future<void> clearSelectedWorkspace() async {
    _selectedWorkspace = null;
    _selectedBusiness = null;
    _profile = null;
    await WorkspaceStorage.clearSelectedWorkspaceId();
    notifyListeners();
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

  /// Обновить бизнес
  Future<Either<Failure, Business>> updateBusinessCall(
    String businessId,
    Business business,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await updateBusiness.call(
      UpdateBusinessParams(id: businessId, business: business),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (updatedBusiness) {
        // Обновляем бизнес в списке
        if (_businesses != null) {
          final index = _businesses!.indexWhere((b) => b.id == updatedBusiness.id);
          if (index != -1) {
            _businesses![index] = updatedBusiness;
          }
        }
        // Обновляем выбранный бизнес, если это он
        if (_selectedBusiness?.id == updatedBusiness.id) {
          _selectedBusiness = updatedBusiness;
        }
        if (_selectedWorkspace?.id == updatedBusiness.id) {
          _selectedWorkspace = updatedBusiness;
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );

    return result;
  }

  /// Создать бизнес
  Future<Either<Failure, Business>> createBusinessCall(
    Business business,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createBusiness.call(
      CreateBusinessParams(business: business),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (createdBusiness) {
        // Добавляем созданный бизнес в список
        if (_businesses == null) {
          _businesses = [];
        }
        _businesses!.add(createdBusiness);
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );

    return result;
  }

  /// Получить сообщение об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
