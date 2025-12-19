import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Параметры для создания согласования
class CreateApprovalParams {
  final Approval approval;

  CreateApprovalParams({required this.approval});
}

/// Use Case для создания согласования
class CreateApproval implements UseCase<Approval, CreateApprovalParams> {
  final ApprovalRepository repository;

  CreateApproval(this.repository);

  @override
  Future<Either<Failure, Approval>> call(CreateApprovalParams params) async {
    return await repository.createApproval(params.approval);
  }
}

