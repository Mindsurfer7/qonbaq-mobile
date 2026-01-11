/// Тип основной деятельности для прихода
enum IncomeArticle {
  MAIN_ACTIVITY,
  FINANCIAL_HELP,
  OTHER_INCOME,
}

/// Категория дохода
enum IncomeCategory {
  MAIN_INCOME,
  SUBSIDY,
  INVESTMENT,
  OTHER,
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

/// Статьи расходов
enum ExpenseArticle {
  PRODUCTION,
  ADMINISTRATIVE,
  MARKETING,
  RENT,
  UTILITIES,
  TRANSPORT,
  EQUIPMENT,
  OTHER,
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

/// Направление транзита
enum TransitDirection {
  OUTGOING, // Исходящий транзит (со счета)
  INCOMING, // Входящий транзит (на счет)
}

/// Тип финансового счета
enum AccountType {
  CASH,
  BANK_ACCOUNT,
  TERMINAL,
  OTHER,
}

