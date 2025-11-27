import 'package:dartz/dartz.dart' hide Task;
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../core/error/failures.dart';
import '../models/task_model.dart';
import '../datasources/task_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория задач
/// Использует Remote DataSource
class TaskRepositoryImpl extends RepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final taskModel = TaskModel.fromEntity(task);
      final createdTask = await remoteDataSource.createTask(taskModel);
      return Right(createdTask.toEntity());
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
}

