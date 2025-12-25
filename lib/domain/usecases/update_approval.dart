import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Параметры для обновления согласования
class UpdateApprovalParams {
  final String approvalId;
  final String? title;
  final String? projectId;
  final double? amount;
  final Map<String, dynamic>? formData;

  UpdateApprovalParams({
    required this.approvalId,
    this.title,
    this.projectId,
    this.amount,
    this.formData,
  });
}

/// Use Case для обновления согласования
class UpdateApproval implements UseCase<Approval, UpdateApprovalParams> {
  final ApprovalRepository repository;

  UpdateApproval(this.repository);

  @override
  Future<Either<Failure, Approval>> call(UpdateApprovalParams params) async {
    return await repository.updateApproval(
      params.approvalId,
      title: params.title,
      projectId: params.projectId,
      amount: params.amount,
      formData: params.formData,
    );
  }
}

