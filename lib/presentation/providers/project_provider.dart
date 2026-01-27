import 'package:flutter/foundation.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/get_business_projects.dart';
import '../../domain/usecases/create_project.dart';
import '../../domain/usecases/update_project.dart';
import '../../domain/usecases/delete_project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием проектов
class ProjectProvider with ChangeNotifier {
  final GetBusinessProjects getBusinessProjects;
  final CreateProject createProject;
  final UpdateProject updateProject;
  final DeleteProject deleteProject;
  final ProjectRepository projectRepository;

  ProjectProvider({
    required this.getBusinessProjects,
    required this.createProject,
    required this.updateProject,
    required this.deleteProject,
    required this.projectRepository,
  });

  List<Project>? _projects;
  Project? _currentProject;
  bool _isLoading = false;
  String? _error;

  /// Список проектов
  List<Project>? get projects => _projects;

  /// Текущий проект (для детального экрана)
  Project? get currentProject => _currentProject;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список проектов бизнеса
  Future<void> loadProjects(
    String businessId, {
    bool includeInactive = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getBusinessProjects.call(
      GetBusinessProjectsParams(
        businessId: businessId,
        includeInactive: includeInactive,
      ),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (projects) {
        _projects = projects;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Создать проект
  Future<bool> createNewProject(Project project) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createProject.call(
      CreateProjectParams(project: project),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (createdProject) {
        // Добавляем новый проект в список
        _projects ??= [];
        _projects!.add(createdProject);
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить проект
  Future<bool> updateExistingProject(
    String projectId,
    Project project,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await updateProject.call(
      UpdateProjectParams(
        projectId: projectId,
        project: project,
      ),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (updatedProject) {
        // Обновляем проект в списке
        if (_projects != null) {
          final index = _projects!.indexWhere(
            (p) => p.id == projectId,
          );
          if (index != -1) {
            _projects![index] = updatedProject;
          }
        }
        // Обновляем текущий проект, если он был выбран
        if (_currentProject?.id == projectId) {
          _currentProject = updatedProject;
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Удалить проект
  Future<bool> removeProject(String projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await deleteProject.call(
      DeleteProjectParams(projectId: projectId),
    );

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (_) {
        // Удаляем проект из списка
        if (_projects != null) {
          _projects!.removeWhere((p) => p.id == projectId);
        }
        // Очищаем текущий проект, если он был удален
        if (_currentProject?.id == projectId) {
          _currentProject = null;
        }
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Загрузить детальную информацию о проекте
  Future<void> loadProjectDetails(String projectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await projectRepository.getProjectById(projectId);

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (project) {
        _currentProject = project;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Очистить все данные
  void clear() {
    debugPrint('🧹 ProjectProvider: Очистка данных');
    _projects = null;
    _currentProject = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Получить сообщение об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ForbiddenFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}



