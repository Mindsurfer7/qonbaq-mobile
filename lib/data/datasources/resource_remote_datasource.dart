import '../../domain/entities/resource.dart';
import '../models/resource_model.dart';

/// Интерфейс удаленного источника данных для ресурсов
abstract class ResourceRemoteDataSource {
  /// Получить список ресурсов бизнеса
  Future<List<ResourceModel>> getBusinessResources(
    String businessId, {
    bool? isActive,
  });

  /// Получить ресурс по ID
  Future<ResourceModel> getResourceById(String id);

  /// Создать ресурс
  Future<ResourceModel> createResource(String businessId, ResourceModel resource);

  /// Обновить ресурс
  Future<ResourceModel> updateResource(String id, ResourceModel resource);

  /// Удалить ресурс
  Future<void> deleteResource(String id);
}


