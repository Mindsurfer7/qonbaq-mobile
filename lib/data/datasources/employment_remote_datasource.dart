import '../models/employment_with_role_model.dart';

/// Интерфейс удаленного источника данных для трудоустройств
abstract class EmploymentRemoteDataSource {
  /// Получить список сотрудников бизнеса с их ролями
  Future<List<EmploymentWithRoleModel>> getBusinessEmploymentsWithRoles(
    String businessId,
  );

  /// Обновить роль одного сотрудника
  Future<EmploymentWithRoleModel> updateEmploymentRole(
    String employmentId,
    String? roleCode,
  );

  /// Назначить роли нескольким сотрудникам
  Future<List<EmploymentWithRoleModel>> assignEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  );

  /// Обновить роли нескольких сотрудников
  Future<List<EmploymentWithRoleModel>> updateEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  );

  /// Обновить employment
  /// Если employmentId == null, обновляется текущее employment через /me
  Future<EmploymentWithRoleModel> updateEmployment({
    String? employmentId,
    String? position,
    String? positionType,
    String? orgPosition,
    String? workPhone,
    int? workExperience,
    String? accountability,
    String? personnelNumber,
    DateTime? hireDate,
    String? roleCode,
    String? businessId,
  });

  /// Назначить функциональные роли сотрудникам
  /// assignments: список назначений, где каждое содержит employmentId и список permissions
  Future<void> assignFunctionalRoles({
    required String businessId,
    required List<Map<String, dynamic>> assignments,
  });
}