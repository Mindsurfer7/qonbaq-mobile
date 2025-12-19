import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

/// Параметры для назначения менеджера подразделения
class SetDepartmentManagerParams {
  final String departmentId;
  final String managerId;

  SetDepartmentManagerParams({
    required this.departmentId,
    required this.managerId,
  });
}

/// Use Case для назначения менеджера подразделения
class SetDepartmentManager
    implements UseCase<Department, SetDepartmentManagerParams> {
  final DepartmentRepository repository;

  SetDepartmentManager(this.repository);

  @override
  Future<Either<Failure, Department>> call(
    SetDepartmentManagerParams params,
  ) async {
    return await repository.setDepartmentManager(
      params.departmentId,
      params.managerId,
    );
  }
}

