import '../entities/entity.dart';
import 'user.dart';

/// Доменная сущность наблюдателя за клиентом
class CustomerObserver extends Entity {
  final String id;
  final String customerId;
  final String userId;
  final DateTime createdAt;
  final User? user;

  const CustomerObserver({
    required this.id,
    required this.customerId,
    required this.userId,
    required this.createdAt,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerObserver &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomerObserver(id: $id, customerId: $customerId, userId: $userId)';
}
