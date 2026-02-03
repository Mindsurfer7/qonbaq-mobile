import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/employment_repository.dart';

/// Параметры для назначения функциональных ролей
class AssignFunctionalRolesParams {
  final String businessId;
  final List<Map<String, dynamic>> assignments;

  AssignFunctionalRolesParams({
    required this.businessId,
    required this.assignments,
  });
}

/// Use Case для назначения функциональных ролей сотрудникам
class AssignFunctionalRoles
    implements UseCase<void, AssignFunctionalRolesParams> {
  final EmploymentRepository repository;

  AssignFunctionalRoles(this.repository);

  @override
  Future<Either<Failure, void>> call(
    AssignFunctionalRolesParams params,
  ) async {
    return await repository.assignFunctionalRoles(
      businessId: params.businessId,
      assignments: params.assignments,
    );
  }
}
