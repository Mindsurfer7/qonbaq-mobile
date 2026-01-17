import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval_decision.dart';
import '../repositories/approval_repository.dart';

/// Параметры для принятия решения по согласованию
class DecideApprovalParams {
  final String approvalId;
  final ApprovalDecisionType decision;
  final String? comment;
  final String? executorId;

  DecideApprovalParams({
    required this.approvalId,
    required this.decision,
    this.comment,
    this.executorId,
  });
}

/// Use Case для принятия решения по согласованию
class DecideApproval implements UseCase<ApprovalDecision, DecideApprovalParams> {
  final ApprovalRepository repository;

  DecideApproval(this.repository);

  @override
  Future<Either<Failure, ApprovalDecision>> call(DecideApprovalParams params) async {
    return await repository.decideApproval(
      params.approvalId,
      params.decision,
      params.comment,
      params.executorId,
    );
  }
}

