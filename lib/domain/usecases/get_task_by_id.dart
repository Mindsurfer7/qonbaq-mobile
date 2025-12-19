import 'package:dartz/dartz.dart' hide Task;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use Case для получения задачи по ID
class GetTaskById implements UseCase<Task, String> {
  final TaskRepository repository;

  GetTaskById(this.repository);

  @override
  Future<Either<Failure, Task>> call(String taskId) async {
    return await repository.getTaskById(taskId);
  }
}


