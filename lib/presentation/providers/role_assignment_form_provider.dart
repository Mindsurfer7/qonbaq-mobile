import 'package:flutter/foundation.dart';

/// Провайдер для хранения данных формы назначения функциональных ролей
class RoleAssignmentFormProvider with ChangeNotifier {
  // Две функциональные роли, которые нужно назначить
  String? _moneyIssuerEmploymentId; // Кто отвечает за выдачу денег (MONEY_ISSUER)
  String? _approvalAuthorizeEmploymentId; // Кто подписывает согласования вместо гендиректора (APPROVAL_AUTHORIZE)

  /// ID трудоустройства для роли "Кто отвечает за выдачу денег"
  String? get moneyIssuerEmploymentId => _moneyIssuerEmploymentId;

  /// ID трудоустройства для роли "Кто подписывает согласования вместо гендиректора"
  String? get approvalAuthorizeEmploymentId => _approvalAuthorizeEmploymentId;

  /// Установить ID трудоустройства для роли "Кто отвечает за выдачу денег"
  void setMoneyIssuer(String? employmentId) {
    _moneyIssuerEmploymentId = employmentId;
    notifyListeners();
  }

  /// Установить ID трудоустройства для роли "Кто подписывает согласования вместо гендиректора"
  void setApprovalAuthorize(String? employmentId) {
    _approvalAuthorizeEmploymentId = employmentId;
    notifyListeners();
  }

  /// Проверка, все ли роли назначены
  bool get isComplete {
    return _moneyIssuerEmploymentId != null &&
        _approvalAuthorizeEmploymentId != null;
  }

  /// Получить все назначения в формате для API
  /// Возвращает список assignments для POST /employment/functional-roles
  List<Map<String, dynamic>> getAssignments() {
    final assignments = <Map<String, dynamic>>[];

    if (_moneyIssuerEmploymentId != null) {
      assignments.add({
        'employmentId': _moneyIssuerEmploymentId,
        'permissions': ['MONEY_ISSUER'],
      });
    }

    if (_approvalAuthorizeEmploymentId != null) {
      assignments.add({
        'employmentId': _approvalAuthorizeEmploymentId,
        'permissions': ['APPROVAL_AUTHORIZE'],
      });
    }

    return assignments;
  }

  /// Очистить все назначения
  void clear() {
    _moneyIssuerEmploymentId = null;
    _approvalAuthorizeEmploymentId = null;
    notifyListeners();
  }
}
