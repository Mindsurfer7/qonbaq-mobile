import '../datasources/datasource.dart';
import '../models/financial_form_model.dart';
import '../models/income_category_model.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/transit_model.dart';
import '../models/financial_report_model.dart';
import '../models/account_model.dart';

/// Удаленный источник данных для финансового блока (API)
abstract class FinancialRemoteDataSource extends DataSource {
  /// Получить форму для создания прихода
  Future<FinancialFormModel> getIncomeForm({required String businessId});

  /// Получить форму для создания расхода
  Future<FinancialFormModel> getExpenseForm({required String businessId});

  /// Получить форму для создания транзита
  Future<FinancialFormModel> getTransitForm({required String businessId});

  /// Получить категории доходов
  Future<List<IncomeCategoryModel>> getIncomeCategories({
    required String businessId,
  });

  /// Создать приход
  Future<IncomeModel> createIncome(IncomeModel income);

  /// Создать расход
  Future<ExpenseModel> createExpense(ExpenseModel expense);

  /// Создать транзит
  Future<TransitModel> createTransit(TransitModel transit);

  /// Получить финансовый отчет
  /// Если указан accountId - отчет по конкретному счету
  /// Если указан projectId - отчет по проекту
  /// Если ничего не указано - отчет по всему бизнесу
  Future<FinancialReportModel> getFinancialReport({
    required String businessId,
    required String startDate, // ISO string
    required String endDate, // ISO string
    String? projectId,
    String? accountId,
  });

  /// Получить список счетов (кошельков)
  Future<List<AccountModel>> getAccounts({
    required String businessId,
    String? projectId,
    String? accountType,
  });

  /// Создать счет
  Future<AccountModel> createAccount(AccountModel account);
}
