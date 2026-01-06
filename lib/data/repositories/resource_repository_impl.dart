import 'package:dartz/dartz.dart';
import '../../domain/entities/resource.dart';
import '../../domain/repositories/resource_repository.dart';
import '../../core/error/failures.dart';
import '../models/resource_model.dart';
import '../datasources/resource_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/resource_remote_datasource_impl.dart' show ValidationException;

/// Реализация репозитория ресурсов
class ResourceRepositoryImpl extends RepositoryImpl implements ResourceRepository {
  final ResourceRemoteDataSource remoteDataSource;

  ResourceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Resource>>> getBusinessResources(
    String businessId, {
    bool? isActive,
  }) async {
    try {
      final resources = await remoteDataSource.getBusinessResources(
        businessId,
        isActive: isActive,
      );
      return Right(resources.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении ресурсов: $e'));
    }
  }

  @override
  Future<Either<Failure, Resource>> getResourceById(String id) async {
    try {
      final resource = await remoteDataSource.getResourceById(id);
      return Right(resource.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении ресурса: $e'));
    }
  }

  @override
  Future<Either<Failure, Resource>> createResource(String businessId, Resource resource) async {
    try {
      final resourceModel = ResourceModel.fromEntity(resource);
      final createdResource = await remoteDataSource.createResource(businessId, resourceModel);
      return Right(createdResource.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании ресурса: $e'));
    }
  }

  @override
  Future<Either<Failure, Resource>> updateResource(String id, Resource resource) async {
    try {
      final resourceModel = ResourceModel.fromEntity(resource);
      final updatedResource = await remoteDataSource.updateResource(id, resourceModel);
      return Right(updatedResource.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении ресурса: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteResource(String id) async {
    try {
      await remoteDataSource.deleteResource(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении ресурса: $e'));
    }
  }
}

