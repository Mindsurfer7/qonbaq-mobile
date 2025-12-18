import 'package:dartz/dartz.dart' hide Task;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Параметры для обновления задачи
class UpdateTaskParams {
  final String id;
  final Task task;

  UpdateTaskParams({required this.id, required this.task});
}

/// Use Case для обновления задачи
class UpdateTask implements UseCase<Task, UpdateTaskParams> {
  final TaskRepository repository;

  UpdateTask(this.repository);

  @override
  Future<Either<Failure, Task>> call(UpdateTaskParams params) async {
    return await repository.updateTask(params.id, params.task);
  }
}

