import '../../domain/entities/income.dart';
import '../../domain/entities/financial_enums.dart';

class IncomeModel extends Income {
  const IncomeModel({
    super.id,
    required super.businessId,
    super.projectId,
    required super.accountId,
    required super.amount,
    required super.currency,
    required super.article,
    required super.periodicity,
    required super.categoryId,
    super.serviceId,
    required super.paymentMethod,
    required super.comment,
    required super.transactionDate,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
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

    return IncomeModel(
      id: json['id'] as String?,
      businessId: json['businessId'] as String,
      projectId: json['projectId'] as String?,
      accountId: json['accountId'] as String,
      amount: amount,
      currency: json['currency'] as String,
      article: IncomeArticle.values.firstWhere(
        (e) => e.name == json['article'],
        orElse: () => IncomeArticle.OTHER_INCOME,
      ),
      periodicity: Periodicity.values.firstWhere(
        (e) => e.name == json['periodicity'],
        orElse: () => Periodicity.CONSTANT,
      ),
      categoryId: json['categoryId'] as String,
      serviceId: json['serviceId'] as String?,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.CASH,
      ),
      comment: json['comment'] as String? ?? '',
      transactionDate: DateTime.parse(json['transactionDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'projectId': projectId,
      'accountId': accountId,
      'amount': amount,
      'currency': currency,
      'article': article.name,
      'periodicity': periodicity.name,
      'categoryId': categoryId,
      'serviceId': serviceId,
      'paymentMethod': paymentMethod.name,
      'comment': comment,
      'transactionDate': transactionDate.toIso8601String(),
    };
  }
}


