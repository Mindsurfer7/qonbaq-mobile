import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/employment_with_role.dart';
import '../repositories/employment_repository.dart';

/// Параметры для обновления ролей сотрудников
class UpdateEmploymentsRolesParams {
  final Map<String, String?> employmentsRoles;

  UpdateEmploymentsRolesParams({required this.employmentsRoles});
}

/// Use Case для обновления ролей нескольких сотрудников
class UpdateEmploymentsRoles
    implements UseCase<List<EmploymentWithRole>, UpdateEmploymentsRolesParams> {
  final EmploymentRepository repository;

  UpdateEmploymentsRoles(this.repository);

  @override
  Future<Either<Failure, List<EmploymentWithRole>>> call(
    UpdateEmploymentsRolesParams params,
  ) async {
    return await repository.updateEmploymentsRoles(params.employmentsRoles);
  }
}