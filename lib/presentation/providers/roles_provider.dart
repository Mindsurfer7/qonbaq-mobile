import 'package:flutter/foundation.dart';
import '../../domain/entities/employment_with_role.dart';
import '../../domain/usecases/get_business_employments_with_roles.dart';
import '../../domain/usecases/update_employments_roles.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием ролей сотрудников
class RolesProvider with ChangeNotifier {
  final GetBusinessEmploymentsWithRoles getBusinessEmploymentsWithRoles;
  final UpdateEmploymentsRoles updateEmploymentsRoles;

  RolesProvider({
    required this.getBusinessEmploymentsWithRoles,
    required this.updateEmploymentsRoles,
  });

  List<EmploymentWithRole>? _employments;
  bool _isLoading = false;
  String? _error;

  /// Список трудоустройств с ролями
  List<EmploymentWithRole>? get employments => _employments;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить сотрудников бизнеса с их ролями
  Future<void> loadEmployments(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getBusinessEmploymentsWithRoles.call(
      GetBusinessEmploymentsWithRolesParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (employments) {
        _employments = employments;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Обновить роли сотрудников
  Future<bool> updateRoles(Map<String, String?> employmentsRoles) async {
    if (employmentsRoles.isEmpty) return true;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await updateEmploymentsRoles.call(
      UpdateEmploymentsRolesParams(employmentsRoles: employmentsRoles),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedEmployments) {
        // Обновляем локальный список
        _updateLocalEmployments(updatedEmployments);
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить локальный список трудоустройств
  void _updateLocalEmployments(List<EmploymentWithRole> updatedEmployments) {
    if (_employments == null) return;

    for (final updatedEmployment in updatedEmployments) {
      final index = _employments!.indexWhere(
        (employment) => employment.id == updatedEmployment.id,
      );
      if (index != -1) {
        _employments![index] = updatedEmployment;
      }
    }
  }

  /// Очистить состояние
  void clear() {
    _employments = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    }
    return 'Произошла неизвестная ошибка';
  }
}