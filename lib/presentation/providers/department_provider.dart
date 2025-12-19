import 'package:flutter/foundation.dart';
import '../../domain/entities/department.dart';
import '../../domain/usecases/get_business_departments.dart';
import '../../domain/usecases/create_department.dart';
import '../../domain/usecases/update_department.dart';
import '../../domain/usecases/delete_department.dart';
import '../../domain/usecases/set_department_manager.dart';
import '../../domain/usecases/remove_department_manager.dart';
import '../../domain/usecases/assign_employee_to_department.dart';
import '../../domain/usecases/remove_employee_from_department.dart';
import '../../domain/usecases/assign_employees_to_department.dart';
import '../../domain/repositories/department_repository.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием подразделений
class DepartmentProvider with ChangeNotifier {
  final GetBusinessDepartments getBusinessDepartments;
  final CreateDepartment createDepartment;
  final UpdateDepartment updateDepartment;
  final DeleteDepartment deleteDepartment;
  final SetDepartmentManager setDepartmentManager;
  final RemoveDepartmentManager removeDepartmentManager;
  final AssignEmployeeToDepartment assignEmployeeToDepartment;
  final RemoveEmployeeFromDepartment removeEmployeeFromDepartment;
  final AssignEmployeesToDepartment assignEmployeesToDepartment;
  final DepartmentRepository departmentRepository;

  DepartmentProvider({
    required this.getBusinessDepartments,
    required this.createDepartment,
    required this.updateDepartment,
    required this.deleteDepartment,
    required this.setDepartmentManager,
    required this.removeDepartmentManager,
    required this.assignEmployeeToDepartment,
    required this.removeEmployeeFromDepartment,
    required this.assignEmployeesToDepartment,
    required this.departmentRepository,
  });

  List<Department>? _departments;
  List<Department>? _departmentsTree;
  Department? _currentDepartment;
  List<Map<String, dynamic>>? _currentDepartmentEmployees;
  bool _isLoading = false;
  String? _error;

  /// Список подразделений
  List<Department>? get departments => _departments;

  /// Дерево подразделений
  List<Department>? get departmentsTree => _departmentsTree;

  /// Текущее подразделение (для детального экрана)
  Department? get currentDepartment => _currentDepartment;

  /// Сотрудники текущего подразделения
  List<Map<String, dynamic>>? get currentDepartmentEmployees =>
      _currentDepartmentEmployees;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список подразделений бизнеса
  Future<void> loadDepartments(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getBusinessDepartments.call(
      GetBusinessDepartmentsParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (departments) {
        _departments = departments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Создать подразделение
  Future<bool> createNewDepartment(Department department) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createDepartment.call(
      CreateDepartmentParams(department: department),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (createdDepartment) {
        // Добавляем новое подразделение в список
        _departments ??= [];
        _departments!.add(createdDepartment);
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить подразделение
  Future<bool> updateExistingDepartment(
    String departmentId,
    Department department,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await updateDepartment.call(
      UpdateDepartmentParams(
        departmentId: departmentId,
        department: department,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedDepartment) {
        // Обновляем подразделение в списке
        if (_departments != null) {
          final index = _departments!.indexWhere(
            (d) => d.id == departmentId,
          );
          if (index != -1) {
            _departments![index] = updatedDepartment;
          }
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Удалить подразделение
  Future<bool> removeDepartment(String departmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await deleteDepartment.call(
      DeleteDepartmentParams(departmentId: departmentId),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Удаляем подразделение из списка
        if (_departments != null) {
          _departments!.removeWhere((d) => d.id == departmentId);
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Загрузить детальную информацию о подразделении
  Future<void> loadDepartmentDetails(String departmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Загружаем подразделение (теперь оно содержит всю информацию)
    final departmentResult = await departmentRepository.getDepartmentById(
      departmentId,
    );

    departmentResult.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (department) async {
        _currentDepartment = department;

        // Если сотрудники уже есть в ответе, используем их
        if (department.employees.isNotEmpty) {
          _currentDepartmentEmployees = department.employees.map((emp) {
            return {
              'employmentId': emp.id, // Используем id как employmentId
              'employee': {
                'id': emp.id,
                'email': emp.email,
                'username': emp.username,
                'firstName': emp.firstName,
                'lastName': emp.lastName,
                'patronymic': emp.patronymic,
                'phone': emp.phone,
                'position': emp.position,
                'orgPosition': emp.orgPosition,
              },
            };
          }).toList();
        } else {
          // Иначе загружаем сотрудников отдельно
          final employeesResult =
              await departmentRepository.getDepartmentEmployees(departmentId);

          employeesResult.fold(
            (failure) {
              _error = _getErrorMessage(failure);
              _isLoading = false;
              notifyListeners();
            },
            (employees) {
              _currentDepartmentEmployees = employees;
              _isLoading = false;
              _error = null;
              notifyListeners();
            },
          );
          return;
        }

        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Загрузить дерево подразделений бизнеса
  Future<void> loadDepartmentsTree(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await departmentRepository.getBusinessDepartmentsTree(
      businessId,
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (departments) {
        _departmentsTree = departments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Назначить менеджера подразделения
  Future<bool> setManager(String departmentId, String managerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await setDepartmentManager.call(
      SetDepartmentManagerParams(
        departmentId: departmentId,
        managerId: managerId,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedDepartment) {
        // Обновляем текущее подразделение
        if (_currentDepartment?.id == departmentId) {
          // Если ответ неполный (нет businessId), перезагружаем полную информацию
          if (updatedDepartment.businessId.isEmpty) {
            // Перезагружаем асинхронно, не блокируя возврат
            loadDepartmentDetails(departmentId);
          } else {
            _currentDepartment = updatedDepartment;
          }
        }
        // Обновляем в списке только если ответ полный
        if (_departments != null && updatedDepartment.businessId.isNotEmpty) {
          final index = _departments!.indexWhere((d) => d.id == departmentId);
          if (index != -1) {
            _departments![index] = updatedDepartment;
          }
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Убрать менеджера подразделения
  Future<bool> removeManager(String departmentId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await removeDepartmentManager.call(
      RemoveDepartmentManagerParams(departmentId: departmentId),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedDepartment) {
        // Обновляем текущее подразделение
        if (_currentDepartment?.id == departmentId) {
          // Если ответ неполный (нет businessId), перезагружаем полную информацию
          if (updatedDepartment.businessId.isEmpty) {
            // Перезагружаем асинхронно, не блокируя возврат
            loadDepartmentDetails(departmentId);
          } else {
            _currentDepartment = updatedDepartment;
          }
        }
        // Обновляем в списке только если ответ полный
        if (_departments != null && updatedDepartment.businessId.isNotEmpty) {
          final index = _departments!.indexWhere((d) => d.id == departmentId);
          if (index != -1) {
            _departments![index] = updatedDepartment;
          }
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Назначить сотрудника в подразделение
  Future<bool> assignEmployee(
    String departmentId,
    String employmentId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await assignEmployeeToDepartment.call(
      AssignEmployeeToDepartmentParams(
        departmentId: departmentId,
        employmentId: employmentId,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Перезагружаем список сотрудников
        if (_currentDepartment?.id == departmentId) {
          loadDepartmentDetails(departmentId);
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Убрать сотрудника из подразделения
  Future<bool> removeEmployee(
    String departmentId,
    String employmentId,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await removeEmployeeFromDepartment.call(
      RemoveEmployeeFromDepartmentParams(
        departmentId: departmentId,
        employmentId: employmentId,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Перезагружаем список сотрудников
        if (_currentDepartment?.id == departmentId) {
          loadDepartmentDetails(departmentId);
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Массовое назначение сотрудников в подразделение
  Future<bool> assignEmployees(
    String departmentId,
    List<String> employmentIds,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await assignEmployeesToDepartment.call(
      AssignEmployeesToDepartmentParams(
        departmentId: departmentId,
        employmentIds: employmentIds,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Перезагружаем список сотрудников
        if (_currentDepartment?.id == departmentId) {
          loadDepartmentDetails(departmentId);
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
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

