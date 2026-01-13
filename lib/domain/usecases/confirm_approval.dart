import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Параметры для подтверждения согласования
class ConfirmApprovalParams {
  final String approvalId;
  final bool isConfirmed;
  final double? amount;
  final String? comment;

  const ConfirmApprovalParams({
    required this.approvalId,
    required this.isConfirmed,
    this.amount,
    this.comment,
  });
}

/// Use Case для подтверждения согласования
class ConfirmApproval implements UseCase<Approval, ConfirmApprovalParams> {
  final ApprovalRepository repository;

  ConfirmApproval(this.repository);

  @override
  Future<Either<Failure, Approval>> call(ConfirmApprovalParams params) async {
    return await repository.confirmApproval(
      params.approvalId,
      isConfirmed: params.isConfirmed,
      amount: params.amount,
      comment: params.comment,
    );
  }
}
