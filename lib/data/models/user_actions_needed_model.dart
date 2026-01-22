import '../../domain/entities/user_actions_needed.dart';
import '../models/model.dart';

/// Модель действий, требуемых от пользователя
class UserActionsNeededModel implements Model {
  final AccountantActionsModel? accountant;

  UserActionsNeededModel({
    this.accountant,
  });

  factory UserActionsNeededModel.fromJson(Map<String, dynamic> json) {
    // Структура: { userActionsNeeded: { accountant: { awaitingPaymentDetails: {...} } } }
    final userActionsNeededJson = json['userActionsNeeded'] as Map<String, dynamic>?;
    
    AccountantActionsModel? accountant;
    if (userActionsNeededJson != null && userActionsNeededJson['accountant'] != null) {
      accountant = AccountantActionsModel.fromJson(
        userActionsNeededJson['accountant'] as Map<String, dynamic>,
      );
    }

    return UserActionsNeededModel(
      accountant: accountant,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (accountant != null) 'accountant': accountant!.toJson(),
    };
  }

  UserActionsNeeded toEntity() {
    return UserActionsNeeded(
      accountant: accountant?.toEntity(),
    );
  }
}

/// Модель действий для бухгалтера
class AccountantActionsModel implements Model {
  final Map<String, bool> awaitingPaymentDetails;

  AccountantActionsModel({
    required this.awaitingPaymentDetails,
  });

  factory AccountantActionsModel.fromJson(Map<String, dynamic> json) {
    final awaitingPaymentDetailsMap = json['awaitingPaymentDetails']
        as Map<String, dynamic>?;
    final awaitingPaymentDetails = awaitingPaymentDetailsMap?.map(
          (key, value) => MapEntry(key, value as bool),
        ) ??
        {};

    return AccountantActionsModel(
      awaitingPaymentDetails: awaitingPaymentDetails,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'awaitingPaymentDetails': awaitingPaymentDetails,
    };
  }

  AccountantActions toEntity() {
    return AccountantActions(
      awaitingPaymentDetails: awaitingPaymentDetails,
    );
  }
}
