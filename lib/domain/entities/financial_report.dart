import 'entity.dart';
import 'income.dart';
import 'expense.dart';
import 'transit.dart';
import 'account.dart';
import 'project.dart';

/// Период отчета
class ReportPeriod {
  final DateTime startDate;
  final DateTime endDate;

  const ReportPeriod({
    required this.startDate,
    required this.endDate,
  });
}

/// Суммарная информация по отчету
class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance; // Доход - Расход
  final double totalOutgoingTransits;
  final double totalIncomingTransits;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.totalOutgoingTransits,
    required this.totalIncomingTransits,
  });
}

/// Данные по счету с транзакциями
class AccountReportData {
  final Account account;
  final List<Income> incomes;
  final List<Expense> expenses;
  final List<Transit> outgoingTransits;
  final List<Transit> incomingTransits;

  const AccountReportData({
    required this.account,
    required this.incomes,
    required this.expenses,
    required this.outgoingTransits,
    required this.incomingTransits,
  });
}

/// Данные по проекту с счетами
class ProjectReportData {
  final Project project;
  final List<AccountReportData> accounts;

  const ProjectReportData({
    required this.project,
    required this.accounts,
  });
}

/// Сущность финансового отчета
/// Поддерживает три режима: по счету, по проекту, по всему бизнесу
class FinancialReport extends Entity {
  final ReportPeriod period;
  final ReportSummary summary;

  // Режим: по конкретному счету
  final Account? account; // Если отчет по одному счету
  final List<Income>? accountIncomes;
  final List<Expense>? accountExpenses;
  final List<Transit>? accountOutgoingTransits;
  final List<Transit>? accountIncomingTransits;

  // Режим: по проекту
  final Project? project; // Если отчет по проекту
  final List<AccountReportData>? projectAccounts;

  // Режим: по всему бизнесу
  final List<ProjectReportData>? businessProjects;

  const FinancialReport({
    required this.period,
    required this.summary,
    this.account,
    this.accountIncomes,
    this.accountExpenses,
    this.accountOutgoingTransits,
    this.accountIncomingTransits,
    this.project,
    this.projectAccounts,
    this.businessProjects,
  });

  /// Тип отчета
  ReportType get reportType {
    if (account != null) return ReportType.byAccount;
    if (project != null) return ReportType.byProject;
    if (businessProjects != null) return ReportType.byBusiness;
    return ReportType.byBusiness;
  }

  /// Итоговый доход (для обратной совместимости)
  @Deprecated('Используйте summary.totalIncome')
  double get totalIncome => summary.totalIncome;

  /// Итоговый расход (для обратной совместимости)
  @Deprecated('Используйте summary.totalExpense')
  double get totalExpense => summary.totalExpense;

  /// Баланс (для обратной совместимости)
  @Deprecated('Используйте summary.balance')
  double get balance => summary.balance;

  /// Получить все доходы (для обратной совместимости)
  @Deprecated('Используйте структурированные данные отчета')
  List<Income> get incomes {
    if (accountIncomes != null) return accountIncomes!;
    if (projectAccounts != null) {
      return projectAccounts!.expand((a) => a.incomes).toList();
    }
    if (businessProjects != null) {
      return businessProjects!
          .expand((p) => p.accounts)
          .expand((a) => a.incomes)
          .toList();
    }
    return [];
  }

  /// Получить все расходы (для обратной совместимости)
  @Deprecated('Используйте структурированные данные отчета')
  List<Expense> get expenses {
    if (accountExpenses != null) return accountExpenses!;
    if (projectAccounts != null) {
      return projectAccounts!.expand((a) => a.expenses).toList();
    }
    if (businessProjects != null) {
      return businessProjects!
          .expand((p) => p.accounts)
          .expand((a) => a.expenses)
          .toList();
    }
    return [];
  }

  /// Получить все транзиты (для обратной совместимости)
  @Deprecated('Используйте структурированные данные отчета')
  List<Transit> get transits {
    final result = <Transit>[];
    if (accountOutgoingTransits != null) result.addAll(accountOutgoingTransits!);
    if (accountIncomingTransits != null) result.addAll(accountIncomingTransits!);
    if (projectAccounts != null) {
      for (final account in projectAccounts!) {
        result.addAll(account.outgoingTransits);
        result.addAll(account.incomingTransits);
      }
    }
    if (businessProjects != null) {
      for (final project in businessProjects!) {
        for (final account in project.accounts) {
          result.addAll(account.outgoingTransits);
          result.addAll(account.incomingTransits);
        }
      }
    }
    return result;
  }
}

/// Тип финансового отчета
enum ReportType {
  byAccount, // По конкретному счету
  byProject, // По проекту
  byBusiness, // По всему бизнесу
}

