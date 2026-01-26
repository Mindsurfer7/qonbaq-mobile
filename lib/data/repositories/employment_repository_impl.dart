import 'package:dartz/dartz.dart';
import '../../domain/entities/employment_with_role.dart';
import '../../domain/repositories/employment_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/employment_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория трудоустройств
class EmploymentRepositoryImpl extends RepositoryImpl implements EmploymentRepository {
  final EmploymentRemoteDataSource remoteDataSource;

  EmploymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<EmploymentWithRole>>> getBusinessEmploymentsWithRoles(
    String businessId,
  ) async {
    try {
      final models = await remoteDataSource.getBusinessEmploymentsWithRoles(businessId);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении сотрудников: $e'));
    }
  }

  @override
  Future<Either<Failure, EmploymentWithRole>> updateEmploymentRole(
    String employmentId,
    String? roleCode,
  ) async {
    try {
      final model = await remoteDataSource.updateEmploymentRole(employmentId, roleCode);
      final entity = model.toEntity();
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении роли: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EmploymentWithRole>>> assignEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  ) async {
    try {
      final models = await remoteDataSource.assignEmploymentsRoles(employmentsRoles);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure('Ошибка при назначении ролей: $e'));
    }
  }

  @override
  Future<Either<Failure, List<EmploymentWithRole>>> updateEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  ) async {
    try {
      final models = await remoteDataSource.updateEmploymentsRoles(employmentsRoles);
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении ролей: $e'));
    }
  }

  @override
  Future<Either<Failure, EmploymentWithRole>> updateEmployment({
    String? employmentId,
    String? position,
    String? positionType,
    String? orgPosition,
    String? workPhone,
    int? workExperience,
    String? accountability,
    String? personnelNumber,
    DateTime? hireDate,
    String? roleCode,
    String? businessId,
  }) async {
    try {
      final model = await remoteDataSource.updateEmployment(
        employmentId: employmentId,
        position: position,
        positionType: positionType,
        orgPosition: orgPosition,
        workPhone: workPhone,
        workExperience: workExperience,
        accountability: accountability,
        personnelNumber: personnelNumber,
        hireDate: hireDate,
        roleCode: roleCode,
        businessId: businessId,
      );
      final entity = model.toEntity();
      return Right(entity);
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении трудоустройства: $e'));
    }
  }
}