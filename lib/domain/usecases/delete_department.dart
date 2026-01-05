import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/department_repository.dart';

/// Параметры для удаления подразделения
class DeleteDepartmentParams {
  final String departmentId;

  DeleteDepartmentParams({required this.departmentId});
}

/// Use Case для удаления подразделения
class DeleteDepartment
    implements UseCase<void, DeleteDepartmentParams> {
  final DepartmentRepository repository;

  DeleteDepartment(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteDepartmentParams params) async {
    return await repository.deleteDepartment(params.departmentId);
  }
}





