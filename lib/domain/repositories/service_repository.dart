import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/service.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с услугами
abstract class ServiceRepository extends Repository {
  /// Получить список услуг бизнеса
  Future<Either<Failure, List<Service>>> getBusinessServices(
    String businessId, {
    bool? isActive,
  });

  /// Получить услугу по ID
  Future<Either<Failure, Service>> getServiceById(String id);

  /// Создать услугу
  Future<Either<Failure, Service>> createService(
    String businessId,
    Service service, {
    List<String>? employmentIds,
  });

  /// Обновить услугу
  Future<Either<Failure, Service>> updateService(String id, Service service);

  /// Удалить услугу
  Future<Either<Failure, void>> deleteService(String id);

  /// Получить список назначений на услугу
  Future<Either<Failure, List<ServiceAssignment>>> getServiceAssignments(
    String serviceId, {
    bool? isActive,
  });

  /// Создать назначение на услугу
  Future<Either<Failure, ServiceAssignment>> createAssignment(
    String serviceId, {
    String? employmentId,
  });

  /// Обновить назначение (включить/выключить доступность)
  Future<Either<Failure, ServiceAssignment>> updateAssignment(
    String id, {
    bool? isActive,
  });

  /// Удалить назначение
  Future<Either<Failure, void>> deleteAssignment(String id);
}

