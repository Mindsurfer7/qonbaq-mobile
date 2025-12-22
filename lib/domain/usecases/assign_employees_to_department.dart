import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/department_repository.dart';

/// Параметры для массового назначения сотрудников в подразделение
class AssignEmployeesToDepartmentParams {
  final String departmentId;
  final List<String> employmentIds;

  AssignEmployeesToDepartmentParams({
    required this.departmentId,
    required this.employmentIds,
  });
}

/// Use Case для массового назначения сотрудников в подразделение
class AssignEmployeesToDepartment
    implements UseCase<void, AssignEmployeesToDepartmentParams> {
  final DepartmentRepository repository;

  AssignEmployeesToDepartment(this.repository);

  @override
  Future<Either<Failure, void>> call(
    AssignEmployeesToDepartmentParams params,
  ) async {
    return await repository.assignEmployeesToDepartment(
      params.departmentId,
      params.employmentIds,
    );
  }
}


