import 'package:dartz/dartz.dart' hide Task;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Параметры для создания задачи
class CreateTaskParams {
  final Task task;
  final String? inboxItemId;

  CreateTaskParams({
    required this.task,
    this.inboxItemId,
  });
}

/// Use Case для создания задачи
class CreateTask implements UseCase<Task, CreateTaskParams> {
  final TaskRepository repository;

  CreateTask(this.repository);

  @override
  Future<Either<Failure, Task>> call(CreateTaskParams params) async {
    return await repository.createTask(params.task, inboxItemId: params.inboxItemId);
  }
}

