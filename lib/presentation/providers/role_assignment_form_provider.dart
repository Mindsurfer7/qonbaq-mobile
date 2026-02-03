import 'package:flutter/foundation.dart';

/// Провайдер для хранения данных формы назначения основных ролей
class RoleAssignmentFormProvider with ChangeNotifier {
  // Три основные роли, которые нужно назначить
  String? _finalApproverEmploymentId; // Кто утверждает (финальный документ/заявку)
  String? _moneyIssuerEmploymentId; // Кто выдает деньги
  String? _documentProcessorEmploymentId; // Кто оформляет документы

  /// ID трудоустройства для роли "Кто утверждает"
  String? get finalApproverEmploymentId => _finalApproverEmploymentId;

  /// ID трудоустройства для роли "Кто выдает деньги"
  String? get moneyIssuerEmploymentId => _moneyIssuerEmploymentId;

  /// ID трудоустройства для роли "Кто оформляет документы"
  String? get documentProcessorEmploymentId => _documentProcessorEmploymentId;

  /// Установить ID трудоустройства для роли "Кто утверждает"
  void setFinalApprover(String? employmentId) {
    _finalApproverEmploymentId = employmentId;
    notifyListeners();
  }

  /// Установить ID трудоустройства для роли "Кто выдает деньги"
  void setMoneyIssuer(String? employmentId) {
    _moneyIssuerEmploymentId = employmentId;
    notifyListeners();
  }

  /// Установить ID трудоустройства для роли "Кто оформляет документы"
  void setDocumentProcessor(String? employmentId) {
    _documentProcessorEmploymentId = employmentId;
    notifyListeners();
  }

  /// Проверка, все ли роли назначены
  bool get isComplete {
    return _finalApproverEmploymentId != null &&
        _moneyIssuerEmploymentId != null &&
        _documentProcessorEmploymentId != null;
  }

  /// Получить все назначения в виде Map для отправки на сервер
  Map<String, String?> getAssignments() {
    return {
      'finalApprover': _finalApproverEmploymentId,
      'moneyIssuer': _moneyIssuerEmploymentId,
      'documentProcessor': _documentProcessorEmploymentId,
    };
  }

  /// Очистить все назначения
  void clear() {
    _finalApproverEmploymentId = null;
    _moneyIssuerEmploymentId = null;
    _documentProcessorEmploymentId = null;
    notifyListeners();
  }
}
