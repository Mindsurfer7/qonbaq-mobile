import 'package:dartz/dartz.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../../core/error/failures.dart';
import '../models/service_model.dart';
import '../datasources/service_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/service_remote_datasource_impl.dart' show ValidationException;


/// Реализация репозитория услуг
class ServiceRepositoryImpl extends RepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Service>>> getBusinessServices(
    String businessId, {
    bool? isActive,
  }) async {
    try {
      final services = await remoteDataSource.getBusinessServices(
        businessId,
        isActive: isActive,
      );
      return Right(services.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении услуг: $e'));
    }
  }

  @override
  Future<Either<Failure, Service>> getServiceById(String id) async {
    try {
      final service = await remoteDataSource.getServiceById(id);
      return Right(service.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении услуги: $e'));
    }
  }

  @override
  Future<Either<Failure, Service>> createService(
    String businessId,
    Service service, {
    List<String>? employmentIds,
  }) async {
    try {
      final serviceModel = ServiceModel.fromEntity(service);
      final createdService = await remoteDataSource.createService(
        businessId,
        serviceModel,
        employmentIds: employmentIds,
      );
      return Right(createdService.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании услуги: $e'));
    }
  }

  @override
  Future<Either<Failure, Service>> updateService(String id, Service service) async {
    try {
      final serviceModel = ServiceModel.fromEntity(service);
      final updatedService = await remoteDataSource.updateService(id, serviceModel);
      return Right(updatedService.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении услуги: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteService(String id) async {
    try {
      await remoteDataSource.deleteService(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении услуги: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ServiceAssignment>>> getServiceAssignments(
    String serviceId, {
    bool? isActive,
  }) async {
    try {
      final assignments = await remoteDataSource.getServiceAssignments(
        serviceId,
        isActive: isActive,
      );
      return Right(assignments.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении назначений: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceAssignment>> createAssignment(
    String serviceId, {
    String? employmentId,
  }) async {
    try {
      final assignment = await remoteDataSource.createAssignment(
        serviceId,
        employmentId: employmentId,
      );
      return Right(assignment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании назначения: $e'));
    }
  }

  @override
  Future<Either<Failure, ServiceAssignment>> updateAssignment(
    String id, {
    bool? isActive,
  }) async {
    try {
      final assignment = await remoteDataSource.updateAssignment(
        id,
        isActive: isActive,
      );
      return Right(assignment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении назначения: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAssignment(String id) async {
    try {
      await remoteDataSource.deleteAssignment(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении назначения: $e'));
    }
  }
}

