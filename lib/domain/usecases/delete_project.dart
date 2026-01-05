import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/project_repository.dart';

/// Параметры для удаления проекта
class DeleteProjectParams {
  final String projectId;

  DeleteProjectParams({required this.projectId});
}

/// Use Case для удаления проекта
class DeleteProject implements UseCase<void, DeleteProjectParams> {
  final ProjectRepository repository;

  DeleteProject(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteProjectParams params) async {
    return await repository.deleteProject(params.projectId);
  }
}



