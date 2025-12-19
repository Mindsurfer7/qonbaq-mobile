import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Use Case для получения согласования по ID
class GetApprovalById implements UseCase<Approval, String> {
  final ApprovalRepository repository;

  GetApprovalById(this.repository);

  @override
  Future<Either<Failure, Approval>> call(String id) async {
    return await repository.getApprovalById(id);
  }
}

