import '../../domain/entities/approval_decision.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';

/// Модель решения по согласованию
class ApprovalDecisionModel extends ApprovalDecision implements Model {
  const ApprovalDecisionModel({
    required super.id,
    required super.approvalId,
    required super.decision,
    super.comment,
    required super.userId,
    required super.createdAt,
    super.user,
  });

  factory ApprovalDecisionModel.fromJson(Map<String, dynamic> json) {
    ProfileUser? user;
    if (json['user'] != null) {
      final userJson = json['user'] as Map<String, dynamic>;
      user = ProfileUser(
        id: userJson['id'] as String,
        email: userJson['email'] as String,
        firstName: userJson['firstName'] as String?,
        lastName: userJson['lastName'] as String?,
        patronymic: userJson['patronymic'] as String?,
        phone: userJson['phone'] as String?,
      );
    }

    return ApprovalDecisionModel(
      id: json['id'] as String,
      approvalId: json['approvalId'] as String,
      decision: _parseDecision(json['decision'] as String),
      comment: json['comment'] as String?,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      user: user,
    );
  }

  static ApprovalDecisionType _parseDecision(String decision) {
    switch (decision.toUpperCase()) {
      case 'APPROVED':
        return ApprovalDecisionType.approved;
      case 'REJECTED':
        return ApprovalDecisionType.rejected;
      default:
        return ApprovalDecisionType.approved;
    }
  }

  static String _decisionToString(ApprovalDecisionType decision) {
    switch (decision) {
      case ApprovalDecisionType.approved:
        return 'APPROVED';
      case ApprovalDecisionType.rejected:
        return 'REJECTED';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approvalId': approvalId,
      'decision': _decisionToString(decision),
      if (comment != null) 'comment': comment,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ApprovalDecision toEntity() {
    return ApprovalDecision(
      id: id,
      approvalId: approvalId,
      decision: decision,
      comment: comment,
      userId: userId,
      createdAt: createdAt,
      user: user,
    );
  }

  factory ApprovalDecisionModel.fromEntity(ApprovalDecision decision) {
    return ApprovalDecisionModel(
      id: decision.id,
      approvalId: decision.approvalId,
      decision: decision.decision,
      comment: decision.comment,
      userId: decision.userId,
      createdAt: decision.createdAt,
      user: decision.user,
    );
  }
}
