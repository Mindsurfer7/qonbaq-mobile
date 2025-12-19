import '../datasources/datasource.dart';
import '../models/department_model.dart';

/// Удаленный источник данных для подразделений (API)
abstract class DepartmentRemoteDataSource extends DataSource {
  /// Получить все подразделения бизнеса
  Future<List<DepartmentModel>> getBusinessDepartments(String businessId);

  /// Получить подразделение по ID
  Future<DepartmentModel> getDepartmentById(String departmentId);

  /// Создать подразделение
  Future<DepartmentModel> createDepartment(DepartmentModel department);

  /// Обновить подразделение
  Future<DepartmentModel> updateDepartment(
    String departmentId,
    DepartmentModel department,
  );

  /// Удалить подразделение
  Future<void> deleteDepartment(String departmentId);

  /// Получить сотрудников подразделения
  Future<List<Map<String, dynamic>>> getDepartmentEmployees(
    String departmentId,
  );

  /// Назначить/изменить менеджера подразделения
  Future<DepartmentModel> setDepartmentManager(
    String departmentId,
    String managerId,
  );

  /// Убрать менеджера подразделения
  Future<DepartmentModel> removeDepartmentManager(String departmentId);

  /// Назначить сотрудника в подразделение
  Future<void> assignEmployeeToDepartment(
    String departmentId,
    String employmentId,
  );

  /// Убрать сотрудника из подразделения
  Future<void> removeEmployeeFromDepartment(
    String departmentId,
    String employmentId,
  );

  /// Массовое назначение сотрудников в подразделение
  Future<void> assignEmployeesToDepartment(
    String departmentId,
    List<String> employmentIds,
  );

  /// Получить дерево подразделений бизнеса
  Future<List<DepartmentModel>> getBusinessDepartmentsTree(String businessId);
}

