import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/resource.dart';
import '../repositories/resource_repository.dart';

/// Параметры для обновления ресурса
class UpdateResourceParams {
  final String id;
  final Resource resource;

  UpdateResourceParams({
    required this.id,
    required this.resource,
  });
}

/// Use Case для обновления ресурса
class UpdateResource implements UseCase<Resource, UpdateResourceParams> {
  final ResourceRepository repository;

  UpdateResource(this.repository);

  @override
  Future<Either<Failure, Resource>> call(UpdateResourceParams params) async {
    return await repository.updateResource(params.id, params.resource);
  }
}



