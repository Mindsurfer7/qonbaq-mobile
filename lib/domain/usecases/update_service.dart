import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Параметры для обновления услуги
class UpdateServiceParams {
  final String id;
  final Service service;

  UpdateServiceParams({
    required this.id,
    required this.service,
  });
}

/// Use Case для обновления услуги
class UpdateService implements UseCase<Service, UpdateServiceParams> {
  final ServiceRepository repository;

  UpdateService(this.repository);

  @override
  Future<Either<Failure, Service>> call(UpdateServiceParams params) async {
    return await repository.updateService(params.id, params.service);
  }
}

