import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/task_comment.dart';
import '../repositories/task_repository.dart';

/// Параметры для обновления комментария
class UpdateTaskCommentParams {
  final String taskId;
  final String commentId;
  final String text;

  UpdateTaskCommentParams({
    required this.taskId,
    required this.commentId,
    required this.text,
  });
}

/// Use Case для обновления комментария
class UpdateTaskComment implements UseCase<TaskComment, UpdateTaskCommentParams> {
  final TaskRepository repository;

  UpdateTaskComment(this.repository);

  @override
  Future<Either<Failure, TaskComment>> call(UpdateTaskCommentParams params) async {
    return await repository.updateComment(params.taskId, params.commentId, params.text);
  }
}




