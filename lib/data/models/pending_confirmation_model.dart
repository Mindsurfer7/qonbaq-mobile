import '../../domain/entities/pending_confirmation.dart';
import '../models/model.dart';
import 'approval_model.dart';
import 'confirmation_model.dart';

/// Модель согласования, требующего подтверждения
class PendingConfirmationModel extends PendingConfirmation implements Model {
  const PendingConfirmationModel({
    required super.approval,
    required super.confirmation,
  });

  factory PendingConfirmationModel.fromJson(Map<String, dynamic> json) {
    // Сначала парсим confirmation, чтобы получить userId для fallback
    final confirmationJson = json['confirmation'] as Map<String, dynamic>;
    final confirmation = ConfirmationModel.fromJson(confirmationJson).toEntity();
    
    // Парсим approval, используя userId из confirmation как fallback для createdBy
    final approvalJson = Map<String, dynamic>.from(json['approval'] as Map<String, dynamic>);
    // Если нет createdBy или initiatorId, используем userId из confirmation
    if (!approvalJson.containsKey('createdBy') && !approvalJson.containsKey('initiatorId')) {
      approvalJson['createdBy'] = confirmation.userId;
    }
    // Если нет paymentDueDate, используем updatedAt как fallback
    if (!approvalJson.containsKey('paymentDueDate')) {
      approvalJson['paymentDueDate'] = approvalJson['updatedAt'] ?? approvalJson['createdAt'];
    }
    
    final approval = ApprovalModel.fromJson(approvalJson).toEntity();

    return PendingConfirmationModel(
      approval: approval,
      confirmation: confirmation,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'approval': ApprovalModel.fromEntity(approval).toJson(),
      'confirmation': ConfirmationModel.fromEntity(confirmation).toJson(),
    };
  }

  PendingConfirmation toEntity() {
    return PendingConfirmation(
      approval: approval,
      confirmation: confirmation,
    );
  }

  factory PendingConfirmationModel.fromEntity(PendingConfirmation pendingConfirmation) {
    return PendingConfirmationModel(
      approval: pendingConfirmation.approval,
      confirmation: pendingConfirmation.confirmation,
    );
  }
}
