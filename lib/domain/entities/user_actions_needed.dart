import 'entity.dart';

/// Доменная сущность действий, требуемых от пользователя
class UserActionsNeeded extends Entity {
  final AccountantActions? accountant;

  const UserActionsNeeded({
    this.accountant,
  });
}

/// Действия для бухгалтера
class AccountantActions extends Entity {
  final Map<String, bool> awaitingPaymentDetails; // { [approvalId]: boolean }

  const AccountantActions({
    required this.awaitingPaymentDetails,
  });
}
