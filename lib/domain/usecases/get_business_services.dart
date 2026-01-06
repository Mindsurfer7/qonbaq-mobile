import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/service.dart';
import '../repositories/service_repository.dart';

/// Параметры для получения списка услуг бизнеса
class GetBusinessServicesParams {
  final String businessId;
  final bool? isActive;

  GetBusinessServicesParams({
    required this.businessId,
    this.isActive,
  });
}

/// Use Case для получения списка услуг бизнеса
class GetBusinessServices implements UseCase<List<Service>, GetBusinessServicesParams> {
  final ServiceRepository repository;

  GetBusinessServices(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(GetBusinessServicesParams params) async {
    return await repository.getBusinessServices(
      params.businessId,
      isActive: params.isActive,
    );
  }
}

