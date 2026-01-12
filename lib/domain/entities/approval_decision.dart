import '../entities/entity.dart';
import 'user_profile.dart';
import 'department.dart';

/// Решение по согласованию
class ApprovalDecision extends Entity {
  final String id;
  final String approvalId;
  final ApprovalDecisionType decision;
  final String? comment;
  final String userId;
  final String? departmentId;
  final DateTime createdAt;
  final ProfileUser? user;
  final DepartmentInfo? department;

  const ApprovalDecision({
    required this.id,
    required this.approvalId,
    required this.decision,
    this.comment,
    required this.userId,
    this.departmentId,
    required this.createdAt,
    this.user,
    this.department,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalDecision &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ApprovalDecision(id: $id, decision: $decision)';
}

/// Тип решения
enum ApprovalDecisionType {
  approved, // Одобрено
  rejected, // Отклонено
  requestChanges, // Запросить изменения
}

