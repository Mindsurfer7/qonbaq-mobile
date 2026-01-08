import 'entity.dart';
import 'financial_enums.dart';

/// Сущность расхода
class Expense extends Entity {
  final String? id;
  final String businessId;
  final String? projectId;
  final String accountId;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String? articleId; // Ссылка на статью расходов (справочник)
  final Periodicity periodicity;
  final String? serviceId;
  final PaymentMethod paymentMethod;
  final String comment;
  final DateTime transactionDate;

  const Expense({
    this.id,
    required this.businessId,
    this.projectId,
    required this.accountId,
    required this.amount,
    required this.currency,
    required this.category,
    this.articleId,
    required this.periodicity,
    this.serviceId,
    required this.paymentMethod,
    required this.comment,
    required this.transactionDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id?.hashCode ?? 0;
}


