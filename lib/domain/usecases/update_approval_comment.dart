import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_comment.dart';
import '../repositories/approval_repository.dart';

/// Параметры для обновления комментария к согласованию
class UpdateApprovalCommentParams {
  final String approvalId;
  final String commentId;
  final String text;

  UpdateApprovalCommentParams({
    required this.approvalId,
    required this.commentId,
    required this.text,
  });
}

/// Use Case для обновления комментария к согласованию
class UpdateApprovalComment implements UseCase<ApprovalComment, UpdateApprovalCommentParams> {
  final ApprovalRepository repository;

  UpdateApprovalComment(this.repository);

  @override
  Future<Either<Failure, ApprovalComment>> call(UpdateApprovalCommentParams params) async {
    return await repository.updateComment(params.approvalId, params.commentId, params.text);
  }
}

