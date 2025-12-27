import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

/// Параметры для создания проекта
class CreateProjectParams {
  final Project project;

  CreateProjectParams({required this.project});
}

/// Use Case для создания проекта
class CreateProject implements UseCase<Project, CreateProjectParams> {
  final ProjectRepository repository;

  CreateProject(this.repository);

  @override
  Future<Either<Failure, Project>> call(CreateProjectParams params) async {
    return await repository.createProject(params.project);
  }
}


