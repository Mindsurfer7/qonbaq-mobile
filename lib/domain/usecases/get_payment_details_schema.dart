import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../repositories/approval_repository.dart';

/// Use Case для получения схемы формы payment details
class GetPaymentDetailsSchema implements UseCase<Map<String, dynamic>, String> {
  final ApprovalRepository repository;

  GetPaymentDetailsSchema(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>>> call(String approvalId) async {
    return await repository.getPaymentDetailsSchema(approvalId);
  }
}
