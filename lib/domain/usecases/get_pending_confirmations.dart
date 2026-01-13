import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/pending_confirmation.dart';
import '../repositories/approval_repository.dart';

/// Параметры для получения списка pending confirmations
class GetPendingConfirmationsParams {
  final String? businessId;

  const GetPendingConfirmationsParams({this.businessId});
}

/// Use Case для получения списка согласований, требующих подтверждения
class GetPendingConfirmations implements UseCase<List<PendingConfirmation>, GetPendingConfirmationsParams> {
  final ApprovalRepository repository;

  GetPendingConfirmations(this.repository);

  @override
  Future<Either<Failure, List<PendingConfirmation>>> call(GetPendingConfirmationsParams params) async {
    return await repository.getPendingConfirmations(businessId: params.businessId);
  }
}
