import 'package:dartz/dartz.dart';
import '../entities/project.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с проектами
/// Реализация находится в data слое
abstract class ProjectRepository extends Repository {
  /// Получить все проекты бизнеса
  Future<Either<Failure, List<Project>>> getBusinessProjects(
    String businessId, {
    bool includeInactive = false,
  });

  /// Получить проект по ID
  Future<Either<Failure, Project>> getProjectById(String id);

  /// Создать проект
  Future<Either<Failure, Project>> createProject(Project project);

  /// Обновить проект
  Future<Either<Failure, Project>> updateProject(
    String projectId,
    Project project,
  );

  /// Удалить проект
  Future<Either<Failure, void>> deleteProject(String projectId);
}



