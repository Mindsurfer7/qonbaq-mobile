import '../entities/entity.dart';
import 'user_profile.dart';

/// Комментарий к согласованию
class ApprovalComment extends Entity {
  final String id;
  final String approvalId;
  final String text;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileUser? user;

  const ApprovalComment({
    required this.id,
    required this.approvalId,
    required this.text,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ApprovalComment(id: $id)';
}

