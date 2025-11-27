import '../datasources/datasource.dart';
import '../../domain/entities/task.dart';
import '../models/task_model.dart';

/// Удаленный источник данных для задач (API)
abstract class TaskRemoteDataSource extends DataSource {
  /// Создать задачу
  Future<TaskModel> createTask(TaskModel task);

  /// Получить задачу по ID
  Future<TaskModel> getTaskById(String id);

  /// Получить список задач
  Future<List<TaskModel>> getTasks({
    String? businessId,
    String? assignedTo,
    String? assignedBy,
    TaskStatus? status,
    TaskPriority? priority,
    bool? isImportant,
    bool? hasControlPoint,
    int? page,
    int? limit,
  });

  /// Обновить задачу
  Future<TaskModel> updateTask(String id, TaskModel task);

  /// Удалить задачу
  Future<void> deleteTask(String id);
}

