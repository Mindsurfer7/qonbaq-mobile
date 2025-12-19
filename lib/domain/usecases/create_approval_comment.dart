import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_comment.dart';
import '../repositories/approval_repository.dart';

/// Параметры для создания комментария к согласованию
class CreateApprovalCommentParams {
  final String approvalId;
  final String text;

  CreateApprovalCommentParams({
    required this.approvalId,
    required this.text,
  });
}

/// Use Case для создания комментария к согласованию
class CreateApprovalComment implements UseCase<ApprovalComment, CreateApprovalCommentParams> {
  final ApprovalRepository repository;

  CreateApprovalComment(this.repository);

  @override
  Future<Either<Failure, ApprovalComment>> call(CreateApprovalCommentParams params) async {
    return await repository.createComment(params.approvalId, params.text);
  }
}

