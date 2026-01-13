import '../entities/entity.dart';
import 'user_profile.dart';

/// Подтверждение получения средств
class Confirmation extends Entity {
  final String id;
  final String approvalId;
  final String userId;
  final bool isConfirmed;
  final double? amount;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileUser? user;

  const Confirmation({
    required this.id,
    required this.approvalId,
    required this.userId,
    required this.isConfirmed,
    this.amount,
    this.comment,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Confirmation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Confirmation(id: $id, approvalId: $approvalId, isConfirmed: $isConfirmed)';
}
