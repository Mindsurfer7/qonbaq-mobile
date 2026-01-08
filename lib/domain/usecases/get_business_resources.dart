import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/resource.dart';
import '../repositories/resource_repository.dart';

/// Параметры для получения списка ресурсов бизнеса
class GetBusinessResourcesParams {
  final String businessId;
  final bool? isActive;

  GetBusinessResourcesParams({
    required this.businessId,
    this.isActive,
  });
}

/// Use Case для получения списка ресурсов бизнеса
class GetBusinessResources implements UseCase<List<Resource>, GetBusinessResourcesParams> {
  final ResourceRepository repository;

  GetBusinessResources(this.repository);

  @override
  Future<Either<Failure, List<Resource>>> call(GetBusinessResourcesParams params) async {
    return await repository.getBusinessResources(
      params.businessId,
      isActive: params.isActive,
    );
  }
}


