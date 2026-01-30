import 'package:dartz/dartz.dart' hide Task;
import '../entities/task.dart';
import '../entities/task_comment.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с задачами
/// Реализация находится в data слое
abstract class TaskRepository extends Repository {
  /// Создать задачу
  Future<Either<Failure, Task>> createTask(Task task, {String? inboxItemId});

  /// Получить задачу по ID
  Future<Either<Failure, Task>> getTaskById(String id);

  /// Получить список задач
  Future<Either<Failure, List<Task>>> getTasks({
    String? businessId,
    String? assignedTo,
    String? assignedBy,
    TaskStatus? status,
    TaskPriority? priority,
    bool? isImportant,
    bool? hasControlPoint,
    bool? dontForget,
    String? customerId,
    bool? hasCustomer,
    bool? hasRecurringTask,
    DateTime? scheduledDate,
    bool? deadlineToday,
    DateTime? deadlineDate,
    String? recurringTaskId,
    String? controlPointId,
    bool? showAll,
    int? page,
    int? limit,
  });

  /// Обновить задачу
  Future<Either<Failure, Task>> updateTask(String id, Task task);

  /// Удалить задачу
  Future<Either<Failure, void>> deleteTask(String id);

  /// Создать комментарий к задаче
  Future<Either<Failure, TaskComment>> createComment(String taskId, String text);

  /// Обновить комментарий
  Future<Either<Failure, TaskComment>> updateComment(String taskId, String commentId, String text);

  /// Удалить комментарий
  Future<Either<Failure, void>> deleteComment(String taskId, String commentId);
}
