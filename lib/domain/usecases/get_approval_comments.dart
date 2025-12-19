import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_comment.dart';
import '../repositories/approval_repository.dart';

/// Use Case для получения списка комментариев к согласованию
class GetApprovalComments implements UseCase<List<ApprovalComment>, String> {
  final ApprovalRepository repository;

  GetApprovalComments(this.repository);

  @override
  Future<Either<Failure, List<ApprovalComment>>> call(String approvalId) async {
    return await repository.getComments(approvalId);
  }
}

