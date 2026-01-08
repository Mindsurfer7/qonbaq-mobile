import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/resource.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с ресурсами
abstract class ResourceRepository extends Repository {
  /// Получить список ресурсов бизнеса
  Future<Either<Failure, List<Resource>>> getBusinessResources(
    String businessId, {
    bool? isActive,
  });

  /// Получить ресурс по ID
  Future<Either<Failure, Resource>> getResourceById(String id);

  /// Создать ресурс
  Future<Either<Failure, Resource>> createResource(String businessId, Resource resource);

  /// Обновить ресурс
  Future<Either<Failure, Resource>> updateResource(String id, Resource resource);

  /// Удалить ресурс
  Future<Either<Failure, void>> deleteResource(String id);
}



