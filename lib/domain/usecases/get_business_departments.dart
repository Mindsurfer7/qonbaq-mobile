import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/department.dart';
import '../repositories/department_repository.dart';

/// Параметры для получения подразделений бизнеса
class GetBusinessDepartmentsParams {
  final String businessId;

  GetBusinessDepartmentsParams({required this.businessId});
}

/// Use Case для получения списка подразделений бизнеса
class GetBusinessDepartments
    implements UseCase<List<Department>, GetBusinessDepartmentsParams> {
  final DepartmentRepository repository;

  GetBusinessDepartments(this.repository);

  @override
  Future<Either<Failure, List<Department>>> call(
    GetBusinessDepartmentsParams params,
  ) async {
    return await repository.getBusinessDepartments(params.businessId);
  }
}



