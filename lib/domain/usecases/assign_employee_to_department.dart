import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/department_repository.dart';

/// Параметры для назначения сотрудника в подразделение
class AssignEmployeeToDepartmentParams {
  final String departmentId;
  final String employmentId;

  AssignEmployeeToDepartmentParams({
    required this.departmentId,
    required this.employmentId,
  });
}

/// Use Case для назначения сотрудника в подразделение
class AssignEmployeeToDepartment
    implements UseCase<void, AssignEmployeeToDepartmentParams> {
  final DepartmentRepository repository;

  AssignEmployeeToDepartment(this.repository);

  @override
  Future<Either<Failure, void>> call(
    AssignEmployeeToDepartmentParams params,
  ) async {
    return await repository.assignEmployeeToDepartment(
      params.departmentId,
      params.employmentId,
    );
  }
}


