/// Тип основной деятельности для прихода
enum IncomeArticle {
  MAIN_ACTIVITY,
  FINANCIAL_HELP,
  OTHER_INCOME,
}

/// Периодичность платежа
enum Periodicity {
  CONSTANT,
  VARIABLE,
}

/// Метод оплаты
enum PaymentMethod {
  BANK_TRANSFER,
  TERMINAL,
  CASH,
}

/// Категории расходов
enum ExpenseCategory {
  COMMON,
  LABOR_FUND,
  TAXES,
  TRAVEL,
}

/// Статьи транзита
enum TransitArticle {
  BETWEEN_BANKS,
  BETWEEN_CASH,
}

/// Метод транзита
enum TransitMethod {
  CASHLESS,
  CASH,
}

/// Тип финансового счета
enum AccountType {
  CASH,
  BANK_ACCOUNT,
  TERMINAL,
  OTHER,
}

