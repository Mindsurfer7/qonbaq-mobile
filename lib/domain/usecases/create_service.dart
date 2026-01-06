import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Параметры для создания услуги
class CreateServiceParams {
  final String businessId;
  final Service service;
  final List<String>? employmentIds;

  CreateServiceParams({
    required this.businessId,
    required this.service,
    this.employmentIds,
  });
}

/// Use Case для создания услуги
class CreateService implements UseCase<Service, CreateServiceParams> {
  final ServiceRepository repository;

  CreateService(this.repository);

  @override
  Future<Either<Failure, Service>> call(CreateServiceParams params) async {
    return await repository.createService(
      params.businessId,
      params.service,
      employmentIds: params.employmentIds,
    );
  }
}

