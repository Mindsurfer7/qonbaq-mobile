import 'package:dartz/dartz.dart';
import '../../domain/entities/department.dart';
import '../../domain/repositories/department_repository.dart';
import '../../core/error/failures.dart';
import '../models/department_model.dart';
import '../datasources/department_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория подразделений
/// Использует Remote DataSource
class DepartmentRepositoryImpl extends RepositoryImpl
    implements DepartmentRepository {
  final DepartmentRemoteDataSource remoteDataSource;

  DepartmentRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Department>>> getBusinessDepartments(
    String businessId,
  ) async {
    try {
      final departments =
          await remoteDataSource.getBusinessDepartments(businessId);
      return Right(departments.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении подразделений: $e'));
    }
  }

  @override
  Future<Either<Failure, Department>> getDepartmentById(
    String departmentId,
  ) async {
    try {
      final department = await remoteDataSource.getDepartmentById(departmentId);
      return Right(department.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении подразделения: $e'));
    }
  }

  @override
  Future<Either<Failure, Department>> createDepartment(
    Department department,
  ) async {
    try {
      final departmentModel = DepartmentModel.fromEntity(department);
      final createdDepartment =
          await remoteDataSource.createDepartment(departmentModel);
      return Right(createdDepartment.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании подразделения: $e'));
    }
  }

  @override
  Future<Either<Failure, Department>> updateDepartment(
    String departmentId,
    Department department,
  ) async {
    try {
      final departmentModel = DepartmentModel.fromEntity(department);
      final updatedDepartment = await remoteDataSource.updateDepartment(
        departmentId,
        departmentModel,
      );
      return Right(updatedDepartment.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении подразделения: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteDepartment(String departmentId) async {
    try {
      await remoteDataSource.deleteDepartment(departmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении подразделения: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getDepartmentEmployees(
    String departmentId,
  ) async {
    try {
      final employees =
          await remoteDataSource.getDepartmentEmployees(departmentId);
      return Right(employees);
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при получении сотрудников подразделения: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Department>> setDepartmentManager(
    String departmentId,
    String managerId,
  ) async {
    try {
      final department =
          await remoteDataSource.setDepartmentManager(departmentId, managerId);
      return Right(department.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при назначении менеджера: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Department>> removeDepartmentManager(
    String departmentId,
  ) async {
    try {
      final department =
          await remoteDataSource.removeDepartmentManager(departmentId);
      return Right(department.toEntity());
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при удалении менеджера: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> assignEmployeeToDepartment(
    String departmentId,
    String employmentId,
  ) async {
    try {
      await remoteDataSource.assignEmployeeToDepartment(
        departmentId,
        employmentId,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при назначении сотрудника: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> removeEmployeeFromDepartment(
    String departmentId,
    String employmentId,
  ) async {
    try {
      await remoteDataSource.removeEmployeeFromDepartment(
        departmentId,
        employmentId,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при удалении сотрудника: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> assignEmployeesToDepartment(
    String departmentId,
    List<String> employmentIds,
  ) async {
    try {
      await remoteDataSource.assignEmployeesToDepartment(
        departmentId,
        employmentIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при массовом назначении сотрудников: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Department>>> getBusinessDepartmentsTree(
    String businessId,
  ) async {
    try {
      final departments =
          await remoteDataSource.getBusinessDepartmentsTree(businessId);
      return Right(departments.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(
        ServerFailure('Ошибка при получении дерева подразделений: $e'),
      );
    }
  }
}

