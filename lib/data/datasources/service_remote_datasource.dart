import '../../domain/entities/service.dart';
import '../models/service_model.dart';
import '../models/service_assignment_model.dart';

/// Интерфейс удаленного источника данных для услуг
abstract class ServiceRemoteDataSource {
  /// Получить список услуг бизнеса
  Future<List<ServiceModel>> getBusinessServices(
    String businessId, {
    bool? isActive,
  });

  /// Получить услугу по ID
  Future<ServiceModel> getServiceById(String id);

  /// Создать услугу
  Future<ServiceModel> createService(
    String businessId,
    ServiceModel service, {
    List<String>? employmentIds,
  });

  /// Обновить услугу
  Future<ServiceModel> updateService(String id, ServiceModel service);

  /// Удалить услугу
  Future<void> deleteService(String id);

  /// Получить список назначений на услугу
  Future<List<ServiceAssignmentModel>> getServiceAssignments(
    String serviceId, {
    bool? isActive,
  });

  /// Создать назначение на услугу
  Future<ServiceAssignmentModel> createAssignment(
    String serviceId, {
    String? employmentId,
    String? resourceId,
  });

  /// Обновить назначение (включить/выключить доступность)
  Future<ServiceAssignmentModel> updateAssignment(
    String id, {
    bool? isActive,
  });

  /// Удалить назначение
  Future<void> deleteAssignment(String id);
}

