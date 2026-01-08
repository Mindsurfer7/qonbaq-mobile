import 'entity.dart';
import 'financial_enums.dart';

/// Счет (кошелек) бизнеса
class Account extends Entity {
  final String id;
  final String name;
  final String businessId;
  final String? projectId;
  final double balance;
  final String currency;
  final AccountType type;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    required this.id,
    required this.name,
    required this.businessId,
    this.projectId,
    required this.balance,
    required this.currency,
    required this.type,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

