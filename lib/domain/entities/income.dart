import 'entity.dart';
import 'financial_enums.dart';

/// Сущность прихода
class Income extends Entity {
  final String? id;
  final String businessId;
  final String? projectId;
  final String accountId;
  final double amount;
  final String currency;
  final IncomeArticle article;
  final Periodicity periodicity;
  final String categoryId;
  final String? serviceId;
  final PaymentMethod paymentMethod;
  final String comment;
  final DateTime transactionDate;

  const Income({
    this.id,
    required this.businessId,
    this.projectId,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.article,
    required this.periodicity,
    required this.categoryId,
    this.serviceId,
    required this.paymentMethod,
    required this.comment,
    required this.transactionDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Income &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id?.hashCode ?? 0;
}


