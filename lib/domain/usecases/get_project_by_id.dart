import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

/// Параметры для получения проекта по ID
class GetProjectByIdParams {
  final String projectId;

  GetProjectByIdParams({required this.projectId});
}

/// Use Case для получения проекта по ID
class GetProjectById implements UseCase<Project, GetProjectByIdParams> {
  final ProjectRepository repository;

  GetProjectById(this.repository);

  @override
  Future<Either<Failure, Project>> call(GetProjectByIdParams params) async {
    return await repository.getProjectById(params.projectId);
  }
}


