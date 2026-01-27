import 'package:flutter/foundation.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/income.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/transit.dart';
import '../../domain/entities/project.dart';
import '../../domain/usecases/create_expense.dart';
import '../../domain/usecases/create_income.dart';
import '../../domain/usecases/create_transit.dart';
import '../../domain/usecases/get_accounts.dart';
import '../../domain/usecases/get_financial_report.dart';
import '../../domain/usecases/get_income_categories.dart';

/// Провайдер для управления финансовым блоком
class FinancialProvider with ChangeNotifier {
  final GetIncomeCategories getIncomeCategoriesUseCase;
  final CreateIncome createIncomeUseCase;
  final CreateExpense createExpenseUseCase;
  final CreateTransit createTransitUseCase;
  final GetFinancialReport getFinancialReportUseCase;
  final GetAccounts getAccountsUseCase;

  FinancialProvider({
    required this.getIncomeCategoriesUseCase,
    required this.createIncomeUseCase,
    required this.createExpenseUseCase,
    required this.createTransitUseCase,
    required this.getFinancialReportUseCase,
    required this.getAccountsUseCase,
  });

  bool _isLoading = false;
  String? _error;
  List<IncomeCategory> _incomeCategories = [];
  List<Account> _accounts = [];
  FinancialReport? _report;
  
  // Состояние выбора на странице
  Project? _selectedProject;
  Account? _selectedAccount;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<IncomeCategory> get incomeCategories => _incomeCategories;
  List<Account> get accounts => _accounts;
  FinancialReport? get report => _report;
  Project? get selectedProject => _selectedProject;
  Account? get selectedAccount => _selectedAccount;

  /// Установить выбранный проект
  void setSelectedProject(Project? project, String businessId) {
    if (_selectedProject?.id == project?.id) return;
    _selectedProject = project;
    _selectedAccount = null; // Сбрасываем счет при смене проекта
    notifyListeners();
    
    // При выборе проекта автоматически подгружаем его счета
    loadAccounts(businessId, projectId: project?.id);
  }

  /// Установить выбранный счет
  void setSelectedAccount(Account? account) {
    if (_selectedAccount?.id == account?.id) return;
    _selectedAccount = account;
    notifyListeners();
  }

  /// Загрузить категории доходов
  Future<void> loadIncomeCategories(String businessId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getIncomeCategoriesUseCase.call(businessId);

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (categories) {
        _incomeCategories = categories;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Загрузить счета (кошельки)
  Future<void> loadAccounts(String businessId, {String? projectId, String? accountType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getAccountsUseCase.call(
      GetAccountsParams(
        businessId: businessId, 
        projectId: projectId,
        accountType: accountType,
      ),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (accounts) {
        _accounts = accounts;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Загрузить финансовый отчет
  Future<void> loadFinancialReport({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getFinancialReportUseCase.call(
      GetFinancialReportParams(
        businessId: businessId,
        startDate: startDate,
        endDate: endDate,
        projectId: projectId,
      ),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (report) {
        _report = report;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Создать приход
  Future<bool> createIncome(Income income) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createIncomeUseCase.call(income);

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (createdIncome) {
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Создать расход
  Future<bool> createExpense(Expense expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createExpenseUseCase.call(expense);

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (createdExpense) {
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Создать транзит
  Future<bool> createTransit(Transit transit) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createTransitUseCase.call(transit);

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (createdTransit) {
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Очистить все данные
  void clear() {
    debugPrint('🧹 FinancialProvider: Очистка данных');
    _incomeCategories = [];
    _accounts = [];
    _report = null;
    _selectedProject = null;
    _selectedAccount = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
