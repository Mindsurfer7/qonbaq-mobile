import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task_comment.dart';
import '../repositories/task_repository.dart';

/// Параметры для создания комментария
class CreateTaskCommentParams {
  final String taskId;
  final String text;

  CreateTaskCommentParams({
    required this.taskId,
    required this.text,
  });
}

/// Use Case для создания комментария к задаче
class CreateTaskComment implements UseCase<TaskComment, CreateTaskCommentParams> {
  final TaskRepository repository;

  CreateTaskComment(this.repository);

  @override
  Future<Either<Failure, TaskComment>> call(CreateTaskCommentParams params) async {
    return await repository.createComment(params.taskId, params.text);
  }
}


