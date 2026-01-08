import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/approval_template.dart';
import '../entities/income_category.dart';
import '../entities/income.dart';
import '../entities/expense.dart';
import '../entities/transit.dart';
import '../entities/financial_report.dart';
import '../entities/account.dart';

/// Репозиторий для финансового блока
abstract class FinancialRepository {
  /// Получить форму для создания прихода
  Future<Either<Failure, ApprovalTemplate>> getIncomeForm({
    required String businessId,
  });

  /// Получить форму для создания расхода
  Future<Either<Failure, ApprovalTemplate>> getExpenseForm({
    required String businessId,
  });

  /// Получить форму для создания транзита
  Future<Either<Failure, ApprovalTemplate>> getTransitForm({
    required String businessId,
  });

  /// Получить категории доходов
  Future<Either<Failure, List<IncomeCategory>>> getIncomeCategories({
    required String businessId,
  });

  /// Создать приход
  Future<Either<Failure, Income>> createIncome(Income income);

  /// Создать расход
  Future<Either<Failure, Expense>> createExpense(Expense expense);

  /// Создать транзит
  Future<Either<Failure, Transit>> createTransit(Transit transit);

  /// Получить финансовый отчет
  Future<Either<Failure, FinancialReport>> getFinancialReport({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
  });

  /// Получить список счетов (кошельков) проекта или бизнеса
  Future<Either<Failure, List<Account>>> getAccounts({
    required String businessId,
    String? projectId,
    String? accountType,
  });

  /// Создать счет
  Future<Either<Failure, Account>> createAccount(Account account);
}
