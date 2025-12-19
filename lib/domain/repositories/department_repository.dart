import '../../core/error/failures.dart';
import '../../domain/entities/department.dart';
import 'package:dartz/dartz.dart';

/// Репозиторий для работы с подразделениями
abstract class DepartmentRepository {
  /// Получить все подразделения бизнеса
  Future<Either<Failure, List<Department>>> getBusinessDepartments(
    String businessId,
  );

  /// Получить подразделение по ID
  Future<Either<Failure, Department>> getDepartmentById(String departmentId);

  /// Создать подразделение
  Future<Either<Failure, Department>> createDepartment(Department department);

  /// Обновить подразделение
  Future<Either<Failure, Department>> updateDepartment(
    String departmentId,
    Department department,
  );

  /// Удалить подразделение
  Future<Either<Failure, void>> deleteDepartment(String departmentId);

  /// Получить сотрудников подразделения
  Future<Either<Failure, List<Map<String, dynamic>>>> getDepartmentEmployees(
    String departmentId,
  );

  /// Назначить/изменить менеджера подразделения
  Future<Either<Failure, Department>> setDepartmentManager(
    String departmentId,
    String managerId,
  );

  /// Убрать менеджера подразделения
  Future<Either<Failure, Department>> removeDepartmentManager(
    String departmentId,
  );

  /// Назначить сотрудника в подразделение
  Future<Either<Failure, void>> assignEmployeeToDepartment(
    String departmentId,
    String employmentId,
  );

  /// Убрать сотрудника из подразделения
  Future<Either<Failure, void>> removeEmployeeFromDepartment(
    String departmentId,
    String employmentId,
  );

  /// Массовое назначение сотрудников в подразделение
  Future<Either<Failure, void>> assignEmployeesToDepartment(
    String departmentId,
    List<String> employmentIds,
  );

  /// Получить дерево подразделений бизнеса
  Future<Either<Failure, List<Department>>> getBusinessDepartmentsTree(
    String businessId,
  );
}

