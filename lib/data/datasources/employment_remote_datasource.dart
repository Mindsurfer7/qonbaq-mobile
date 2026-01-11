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
}