import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/approval_repository.dart';

/// Параметры для удаления комментария к согласованию
class DeleteApprovalCommentParams {
  final String approvalId;
  final String commentId;

  DeleteApprovalCommentParams({
    required this.approvalId,
    required this.commentId,
  });
}

/// Use Case для удаления комментария к согласованию
class DeleteApprovalComment implements UseCase<void, DeleteApprovalCommentParams> {
  final ApprovalRepository repository;

  DeleteApprovalComment(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteApprovalCommentParams params) async {
    return await repository.deleteComment(params.approvalId, params.commentId);
  }
}

