import '../../domain/entities/financial_report.dart';
import 'income_model.dart';
import 'expense_model.dart';
import 'transit_model.dart';

class FinancialReportModel extends FinancialReport {
  const FinancialReportModel({
    required super.incomes,
    required super.expenses,
    required super.transits,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    return FinancialReportModel(
      incomes: (json['incomes'] as List<dynamic>)
          .map((e) => IncomeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (json['expenses'] as List<dynamic>)
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      transits: (json['transits'] as List<dynamic>)
          .map((e) => TransitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

