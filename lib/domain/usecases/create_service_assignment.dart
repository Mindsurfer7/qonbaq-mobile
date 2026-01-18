import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Параметры для создания назначения на услугу
class CreateServiceAssignmentParams {
  final String serviceId;
  final String? employmentId;

  CreateServiceAssignmentParams({
    required this.serviceId,
    this.employmentId,
  });
}

/// Use Case для создания назначения на услугу
class CreateServiceAssignment
    implements UseCase<ServiceAssignment, CreateServiceAssignmentParams> {
  final ServiceRepository repository;

  CreateServiceAssignment(this.repository);

  @override
  Future<Either<Failure, ServiceAssignment>> call(
    CreateServiceAssignmentParams params,
  ) async {
    return await repository.createAssignment(
      params.serviceId,
      employmentId: params.employmentId,
    );
  }
}
