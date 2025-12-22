import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/task_repository.dart';

/// Параметры для удаления комментария
class DeleteTaskCommentParams {
  final String taskId;
  final String commentId;

  DeleteTaskCommentParams({
    required this.taskId,
    required this.commentId,
  });
}

/// Use Case для удаления комментария
class DeleteTaskComment implements UseCase<void, DeleteTaskCommentParams> {
  final TaskRepository repository;

  DeleteTaskComment(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteTaskCommentParams params) async {
    return await repository.deleteComment(params.taskId, params.commentId);
  }
}



