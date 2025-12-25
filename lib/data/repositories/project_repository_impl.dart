import 'package:dartz/dartz.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../core/error/failures.dart';
import '../models/project_model.dart';
import '../datasources/project_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/project_remote_datasource_impl.dart';

/// Реализация репозитория проектов
/// Использует Remote DataSource
class ProjectRepositoryImpl extends RepositoryImpl implements ProjectRepository {
  final ProjectRemoteDataSource remoteDataSource;

  ProjectRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Project>>> getBusinessProjects(
    String businessId, {
    bool includeInactive = false,
  }) async {
    try {
      final projects = await remoteDataSource.getBusinessProjects(
        businessId,
        includeInactive: includeInactive,
      );
      return Right(projects.map((model) => model.toEntity()).toList());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении проектов: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> getProjectById(String id) async {
    try {
      final project = await remoteDataSource.getProjectById(id);
      return Right(project.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении проекта: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> createProject(Project project) async {
    try {
      final projectModel = ProjectModel.fromEntity(project);
      final createdProject = await remoteDataSource.createProject(projectModel);
      return Right(createdProject.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании проекта: $e'));
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(
    String projectId,
    Project project,
  ) async {
    try {
      final projectModel = ProjectModel.fromEntity(project);
      final updatedProject = await remoteDataSource.updateProject(
        projectId,
        projectModel,
      );
      return Right(updatedProject.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении проекта: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(String projectId) async {
    try {
      await remoteDataSource.deleteProject(projectId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении проекта: $e'));
    }
  }
}

