import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

/// Параметры для создания подразделения
class CreateDepartmentParams {
  final Department department;

  CreateDepartmentParams({required this.department});
}

/// Use Case для создания подразделения
class CreateDepartment
    implements UseCase<Department, CreateDepartmentParams> {
  final DepartmentRepository repository;

  CreateDepartment(this.repository);

  @override
  Future<Either<Failure, Department>> call(
    CreateDepartmentParams params,
  ) async {
    return await repository.createDepartment(params.department);
  }
}


