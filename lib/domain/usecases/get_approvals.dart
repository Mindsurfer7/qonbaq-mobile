import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Параметры для получения списка согласований
class GetApprovalsParams {
  final String? businessId;
  final ApprovalStatus? status;
  final String? createdBy;
  final bool? canApprove;
  final int? page;
  final int? limit;

  GetApprovalsParams({
    this.businessId,
    this.status,
    this.createdBy,
    this.canApprove,
    this.page,
    this.limit,
  });
}

/// Use Case для получения списка согласований
class GetApprovals implements UseCase<List<Approval>, GetApprovalsParams> {
  final ApprovalRepository repository;

  GetApprovals(this.repository);

  @override
  Future<Either<Failure, List<Approval>>> call(GetApprovalsParams params) async {
    return await repository.getApprovals(
      businessId: params.businessId,
      status: params.status,
      createdBy: params.createdBy,
      canApprove: params.canApprove,
      page: params.page,
      limit: params.limit,
    );
  }
}

