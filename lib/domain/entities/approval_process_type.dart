/// Enum процессов согласований
enum ApprovalProcessType {
  /// Заявка на безналичную оплату
  cashlessPaymentRequest(
    'CASHLESS_PAYMENT_REQUEST',
    'Заявка на безналичную оплату',
    'Заявка на безналичную оплату (15)',
  ),

  /// Заявка на наличные средства
  cashPaymentRequest(
    'CASH_PAYMENT_REQUEST',
    'Заявка на наличные средства',
    'Заявка на наличные средства (5)',
  ),

  /// Согласование и утверждение документа
  documentApproval(
    'DOCUMENT_APPROVAL',
    'Согласование и утверждение документа',
    'Согласование и утверждение документа',
  ),

  /// Заявление в командировку
  businessTripRequest(
    'BUSINESS_TRIP_REQUEST',
    'Заявление в командировку',
    'Заявление в командировку',
  ),

  /// Заявление в отпуск
  vacationRequest(
    'VACATION_REQUEST',
    'Заявление в отпуск',
    'Заявление в отпуск',
  ),

  /// Заключение договора с поставщиком
  supplierContractApproval(
    'SUPPLIER_CONTRACT_APPROVAL',
    'Заключение договора с поставщиком',
    'Заключение договора с поставщиком',
  ),

  /// Инвентаризация
  inventory(
    'INVENTORY',
    'Инвентаризация',
    'Инвентаризация',
  ),

  /// Лист стажировки
  internshipSheet(
    'INTERNSHIP_SHEET',
    'Лист стажировки',
    'Лист стажировки',
  ),

  /// Заявление по приему на работу
  employmentRequest(
    'EMPLOYMENT_REQUEST',
    'Заявление по приему на работу',
    'Заявление по приему на работу',
  ),

  /// Заявление об увольнении
  dismissalRequest(
    'DISMISSAL_REQUEST',
    'Заявление об увольнении',
    'Заявление об увольнении',
  ),

  /// Обходной лист
  clearanceSheet(
    'CLEARANCE_SHEET',
    'Обходной лист',
    'Обходной лист',
  );

  /// Внутренний код (английский, для бэкенда)
  final String code;

  /// Русское название для отображения
  final String nameRu;

  /// Описание процесса
  final String description;

  const ApprovalProcessType(this.code, this.nameRu, this.description);

  /// Получить тип процесса по коду
  static ApprovalProcessType? fromCode(String code) {
    try {
      return ApprovalProcessType.values.firstWhere(
        (type) => type.code == code,
      );
    } catch (e) {
      return null;
    }
  }

  /// Получить тип процесса по русскому названию
  static ApprovalProcessType? fromNameRu(String nameRu) {
    try {
      return ApprovalProcessType.values.firstWhere(
        (type) => type.nameRu == nameRu,
      );
    } catch (e) {
      return null;
    }
  }
}

