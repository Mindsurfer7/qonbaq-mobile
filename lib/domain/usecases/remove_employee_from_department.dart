import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/department_repository.dart';

/// Параметры для удаления сотрудника из подразделения
class RemoveEmployeeFromDepartmentParams {
  final String departmentId;
  final String employmentId;

  RemoveEmployeeFromDepartmentParams({
    required this.departmentId,
    required this.employmentId,
  });
}

/// Use Case для удаления сотрудника из подразделения
class RemoveEmployeeFromDepartment
    implements UseCase<void, RemoveEmployeeFromDepartmentParams> {
  final DepartmentRepository repository;

  RemoveEmployeeFromDepartment(this.repository);

  @override
  Future<Either<Failure, void>> call(
    RemoveEmployeeFromDepartmentParams params,
  ) async {
    return await repository.removeEmployeeFromDepartment(
      params.departmentId,
      params.employmentId,
    );
  }
}

