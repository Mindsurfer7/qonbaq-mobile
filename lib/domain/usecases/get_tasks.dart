import 'package:dartz/dartz.dart' hide Task;
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Параметры для получения списка задач
class GetTasksParams {
  final String? businessId;
  final String? assignedTo;
  final String? assignedBy;
  final TaskStatus? status;
  final TaskPriority? priority;
  final bool? isImportant;
  final bool? hasControlPoint;
  final int? page;
  final int? limit;

  GetTasksParams({
    this.businessId,
    this.assignedTo,
    this.assignedBy,
    this.status,
    this.priority,
    this.isImportant,
    this.hasControlPoint,
    this.page,
    this.limit,
  });
}

/// Use Case для получения списка задач
class GetTasks implements UseCase<List<Task>, GetTasksParams> {
  final TaskRepository repository;

  GetTasks(this.repository);

  @override
  Future<Either<Failure, List<Task>>> call(GetTasksParams params) async {
    return await repository.getTasks(
      businessId: params.businessId,
      assignedTo: params.assignedTo,
      assignedBy: params.assignedBy,
      status: params.status,
      priority: params.priority,
      isImportant: params.isImportant,
      hasControlPoint: params.hasControlPoint,
      page: params.page,
      limit: params.limit,
    );
  }
}
