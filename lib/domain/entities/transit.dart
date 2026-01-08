import 'entity.dart';
import 'financial_enums.dart';

/// Сущность транзита (перевод между счетами)
class Transit extends Entity {
  final String? id;
  final String businessId;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final TransitArticle article;
  final TransitMethod method;
  final String comment;
  final DateTime transactionDate;
  // Для отчетов: направление транзита и связанный счет
  final TransitDirection? direction;
  final String? relatedAccountId; // ID связанного счета (для outgoing - toAccountId, для incoming - fromAccountId)

  const Transit({
    this.id,
    required this.businessId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.article,
    required this.method,
    required this.comment,
    required this.transactionDate,
    this.direction,
    this.relatedAccountId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transit &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id?.hashCode ?? 0;
}

