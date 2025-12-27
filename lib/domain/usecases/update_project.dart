import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

/// Параметры для обновления проекта
class UpdateProjectParams {
  final String projectId;
  final Project project;

  UpdateProjectParams({
    required this.projectId,
    required this.project,
  });
}

/// Use Case для обновления проекта
class UpdateProject implements UseCase<Project, UpdateProjectParams> {
  final ProjectRepository repository;

  UpdateProject(this.repository);

  @override
  Future<Either<Failure, Project>> call(UpdateProjectParams params) async {
    return await repository.updateProject(params.projectId, params.project);
  }
}


