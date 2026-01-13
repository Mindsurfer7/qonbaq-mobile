import '../entities/entity.dart';
import 'approval.dart';
import 'confirmation.dart';

/// Согласование, требующее подтверждения
class PendingConfirmation extends Entity {
  final Approval approval;
  final Confirmation confirmation;

  const PendingConfirmation({
    required this.approval,
    required this.confirmation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingConfirmation &&
          runtimeType == other.runtimeType &&
          approval.id == other.approval.id &&
          confirmation.id == other.confirmation.id;

  @override
  int get hashCode => approval.id.hashCode ^ confirmation.id.hashCode;

  @override
  String toString() => 'PendingConfirmation(approvalId: ${approval.id}, confirmationId: ${confirmation.id})';
}
