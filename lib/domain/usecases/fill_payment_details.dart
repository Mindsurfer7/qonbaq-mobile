import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../entities/approval.dart';
import '../repositories/approval_repository.dart';

/// Параметры для заполнения платежных реквизитов
class FillPaymentDetailsParams {
  final String approvalId;
  final String paymentMethod; // "CASH" | "BANK_TRANSFER" | "TERMINAL"
  final String? accountId; // Для CASH
  final String? fromAccountId; // Для BANK_TRANSFER/TERMINAL

  FillPaymentDetailsParams({
    required this.approvalId,
    required this.paymentMethod,
    this.accountId,
    this.fromAccountId,
  });
}

/// Use Case для заполнения платежных реквизитов
class FillPaymentDetails implements UseCase<Approval, FillPaymentDetailsParams> {
  final ApprovalRepository repository;

  FillPaymentDetails(this.repository);

  @override
  Future<Either<Failure, Approval>> call(FillPaymentDetailsParams params) async {
    return await repository.fillPaymentDetails(
      params.approvalId,
      paymentMethod: params.paymentMethod,
      accountId: params.accountId,
      fromAccountId: params.fromAccountId,
    );
  }
}
