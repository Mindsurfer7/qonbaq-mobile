import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

/// Параметры для получения проектов бизнеса
class GetBusinessProjectsParams {
  final String businessId;
  final bool includeInactive;

  GetBusinessProjectsParams({
    required this.businessId,
    this.includeInactive = false,
  });
}

/// Use Case для получения проектов бизнеса
class GetBusinessProjects
    implements UseCase<List<Project>, GetBusinessProjectsParams> {
  final ProjectRepository repository;

  GetBusinessProjects(this.repository);

  @override
  Future<Either<Failure, List<Project>>> call(
    GetBusinessProjectsParams params,
  ) async {
    return await repository.getBusinessProjects(
      params.businessId,
      includeInactive: params.includeInactive,
    );
  }
}

