import 'entity.dart';
import 'income.dart';
import 'expense.dart';
import 'transit.dart';

/// Сущность финансового отчета
class FinancialReport extends Entity {
  final List<Income> incomes;
  final List<Expense> expenses;
  final List<Transit> transits;

  const FinancialReport({
    required this.incomes,
    required this.expenses,
    required this.transits,
  });

  /// Итоговый доход
  double get totalIncome => incomes.fold(0, (sum, item) => sum + item.amount);

  /// Итоговый расход
  double get totalExpense => expenses.fold(0, (sum, item) => sum + item.amount);

  /// Баланс (Доход - Расход)
  double get balance => totalIncome - totalExpense;
}

