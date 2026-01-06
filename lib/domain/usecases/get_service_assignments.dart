import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Параметры для получения назначений на услугу
class GetServiceAssignmentsParams {
  final String serviceId;
  final bool? isActive;

  GetServiceAssignmentsParams({
    required this.serviceId,
    this.isActive,
  });
}

/// Use Case для получения назначений на услугу
class GetServiceAssignments implements UseCase<List<ServiceAssignment>, GetServiceAssignmentsParams> {
  final ServiceRepository repository;

  GetServiceAssignments(this.repository);

  @override
  Future<Either<Failure, List<ServiceAssignment>>> call(GetServiceAssignmentsParams params) async {
    return await repository.getServiceAssignments(
      params.serviceId,
      isActive: params.isActive,
    );
  }
}

