import 'package:dartz/dartz.dart' hide Task;
import '../../domain/entities/task.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/error/failures.dart';
import '../models/task_model.dart';
import '../datasources/task_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/task_remote_datasource_impl.dart';

/// Реализация репозитория задач
/// Использует Remote DataSource
class TaskRepositoryImpl extends RepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Task>> createTask(Task task, {String? inboxItemId}) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final createdTask = await remoteDataSource.createTask(taskModel, inboxItemId: inboxItemId);
      return Right(createdTask.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании задачи: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> getTaskById(String id) async {
    try {
      final task = await remoteDataSource.getTaskById(id);
      return Right(task.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении задачи: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getTasks({
    String? businessId,
    String? assignedTo,
    String? assignedBy,
    TaskStatus? status,
    TaskPriority? priority,
    bool? isImportant,
    bool? hasControlPoint,
    bool? dontForget,
    int? page,
    int? limit,
  }) async {
    try {
      final tasks = await remoteDataSource.getTasks(
        businessId: businessId,
        assignedTo: assignedTo,
        assignedBy: assignedBy,
        status: status,
        priority: priority,
        isImportant: isImportant,
        hasControlPoint: hasControlPoint,
        dontForget: dontForget,
        page: page,
        limit: limit,
      );
      return Right(tasks.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении задач: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(String id, Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final updatedTask = await remoteDataSource.updateTask(id, taskModel);
      return Right(updatedTask.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении задачи: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String id) async {
    try {
      await remoteDataSource.deleteTask(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении задачи: $e'));
    }
  }

  @override
  Future<Either<Failure, TaskComment>> createComment(String taskId, String text) async {
    try {
      final comment = await remoteDataSource.createComment(taskId, text);
      return Right(comment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании комментария: $e'));
    }
  }

  @override
  Future<Either<Failure, TaskComment>> updateComment(String taskId, String commentId, String text) async {
    try {
      final comment = await remoteDataSource.updateComment(taskId, commentId, text);
      return Right(comment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении комментария: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String taskId, String commentId) async {
    try {
      await remoteDataSource.deleteComment(taskId, commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении комментария: $e'));
    }
  }
}

