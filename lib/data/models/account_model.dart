import '../../domain/entities/account.dart';
import '../../domain/entities/financial_enums.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.businessId,
    super.projectId,
    required super.balance,
    required super.currency,
    required super.type,
    super.description,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AccountModel.fromJson(
    Map<String, dynamic> json, {
    String? businessId,
  }) {
    // Обработка balance - может быть строкой или числом
    double balanceValue;
    final balance = json['balance'];
    if (balance is num) {
      balanceValue = balance.toDouble();
    } else if (balance is String) {
      balanceValue = double.tryParse(balance) ?? 0.0;
    } else {
      balanceValue = 0.0;
    }

    // Обработка businessId - может отсутствовать в ответе, используем переданный или из JSON
    final businessIdValue = businessId ?? json['businessId'] as String?;
    if (businessIdValue == null) {
      throw Exception('businessId is required but missing in API response');
    }

    // Обработка дат - могут отсутствовать в ответе
    DateTime createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt'] as String);
    } else {
      createdAt = DateTime.now(); // Дефолтное значение если отсутствует
    }

    DateTime updatedAt;
    if (json['updatedAt'] != null) {
      updatedAt = DateTime.parse(json['updatedAt'] as String);
    } else {
      updatedAt = DateTime.now(); // Дефолтное значение если отсутствует
    }

    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      businessId: businessIdValue,
      projectId: json['projectId'] as String?,
      balance: balanceValue,
      currency: json['currency'] as String,
      type: _parseAccountType(json['type'] as String),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static AccountType _parseAccountType(String type) {
    switch (type) {
      case 'CASH':
        return AccountType.CASH;
      case 'BANK_ACCOUNT':
        return AccountType.BANK_ACCOUNT;
      case 'TERMINAL':
        return AccountType.TERMINAL;
      case 'OTHER':
        return AccountType.OTHER;
      default:
        return AccountType.OTHER;
    }
  }

  static String _accountTypeToString(AccountType type) {
    switch (type) {
      case AccountType.CASH:
        return 'CASH';
      case AccountType.BANK_ACCOUNT:
        return 'BANK_ACCOUNT';
      case AccountType.TERMINAL:
        return 'TERMINAL';
      case AccountType.OTHER:
        return 'OTHER';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessId': businessId,
      'projectId': projectId,
      'balance': balance,
      'currency': currency,
      'type': _accountTypeToString(type),
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразует модель в JSON для создания счета (без id, createdAt, updatedAt)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'type': _accountTypeToString(type),
      'currency': currency,
      'businessId': businessId,
      if (projectId != null) 'projectId': projectId,
      if (description != null) 'description': description,
    };
  }
}

