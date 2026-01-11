import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/employment_with_role.dart';
import '../repositories/employment_repository.dart';

/// Параметры для получения сотрудников бизнеса с ролями
class GetBusinessEmploymentsWithRolesParams {
  final String businessId;

  GetBusinessEmploymentsWithRolesParams({required this.businessId});
}

/// Use Case для получения списка сотрудников бизнеса с их ролями
class GetBusinessEmploymentsWithRoles
    implements UseCase<List<EmploymentWithRole>, GetBusinessEmploymentsWithRolesParams> {
  final EmploymentRepository repository;

  GetBusinessEmploymentsWithRoles(this.repository);

  @override
  Future<Either<Failure, List<EmploymentWithRole>>> call(
    GetBusinessEmploymentsWithRolesParams params,
  ) async {
    return await repository.getBusinessEmploymentsWithRoles(params.businessId);
  }
}