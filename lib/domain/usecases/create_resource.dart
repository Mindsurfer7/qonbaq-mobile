import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/resource.dart';
import '../repositories/resource_repository.dart';

/// Параметры для создания ресурса
class CreateResourceParams {
  final String businessId;
  final Resource resource;

  CreateResourceParams({
    required this.businessId,
    required this.resource,
  });
}

/// Use Case для создания ресурса
class CreateResource implements UseCase<Resource, CreateResourceParams> {
  final ResourceRepository repository;

  CreateResource(this.repository);

  @override
  Future<Either<Failure, Resource>> call(CreateResourceParams params) async {
    return await repository.createResource(params.businessId, params.resource);
  }
}

