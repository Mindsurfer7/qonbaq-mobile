import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

/// Параметры для обновления подразделения
class UpdateDepartmentParams {
  final String departmentId;
  final Department department;

  UpdateDepartmentParams({
    required this.departmentId,
    required this.department,
  });
}

/// Use Case для обновления подразделения
class UpdateDepartment
    implements UseCase<Department, UpdateDepartmentParams> {
  final DepartmentRepository repository;

  UpdateDepartment(this.repository);

  @override
  Future<Either<Failure, Department>> call(
    UpdateDepartmentParams params,
  ) async {
    return await repository.updateDepartment(
      params.departmentId,
      params.department,
    );
  }
}


