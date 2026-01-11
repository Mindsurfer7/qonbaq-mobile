import '../../domain/entities/transit.dart';
import '../../domain/entities/financial_enums.dart';

class TransitModel extends Transit {
  const TransitModel({
    super.id,
    required super.businessId,
    required super.fromAccountId,
    required super.toAccountId,
    required super.amount,
    required super.article,
    required super.method,
    required super.comment,
    required super.transactionDate,
    super.direction,
    super.relatedAccountId,
  });

  factory TransitModel.fromJson(Map<String, dynamic> json) {
    TransitDirection? direction;
    if (json['direction'] != null) {
      try {
        direction = TransitDirection.values.firstWhere(
          (e) => e.name == json['direction'],
        );
      } catch (e) {
        direction = null;
      }
    }

    // Парсим amount: может быть как строкой, так и числом
    double amount;
    final amountValue = json['amount'];
    if (amountValue is num) {
      amount = amountValue.toDouble();
    } else if (amountValue is String) {
      amount = double.parse(amountValue);
    } else {
      throw FormatException('Поле amount должно быть числом или строкой, получено: $amountValue (${amountValue.runtimeType})');
    }

    return TransitModel(
      id: json['id'] as String?,
      businessId: json['businessId'] as String,
      fromAccountId: json['fromAccountId'] as String,
      toAccountId: json['toAccountId'] as String,
      amount: amount,
      article: TransitArticle.values.firstWhere(
        (e) => e.name == json['article'],
        orElse: () => TransitArticle.BETWEEN_BANKS,
      ),
      method: TransitMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => TransitMethod.CASH,
      ),
      comment: json['comment'] as String? ?? '',
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      direction: direction,
      relatedAccountId: json['relatedAccountId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'article': article.name,
      'method': method.name,
      'comment': comment,
      'transactionDate': transactionDate.toIso8601String(),
      if (direction != null) 'direction': direction!.name,
      if (relatedAccountId != null) 'relatedAccountId': relatedAccountId,
    };
  }
}

