import '../datasources/datasource.dart';
import '../models/project_model.dart';

/// Удаленный источник данных для проектов (API)
abstract class ProjectRemoteDataSource extends DataSource {
  /// Получить все проекты бизнеса
  Future<List<ProjectModel>> getBusinessProjects(
    String businessId, {
    bool includeInactive = false,
  });

  /// Получить проект по ID
  Future<ProjectModel> getProjectById(String id);

  /// Создать проект
  Future<ProjectModel> createProject(ProjectModel project);

  /// Обновить проект
  Future<ProjectModel> updateProject(
    String projectId,
    ProjectModel project,
  );

  /// Удалить проект
  Future<void> deleteProject(String projectId);
}

