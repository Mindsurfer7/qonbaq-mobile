import '../../domain/entities/financial_report.dart';
import '../../domain/entities/income.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/transit.dart';
import '../../domain/entities/financial_enums.dart';
import 'income_model.dart';
import 'expense_model.dart';
import 'transit_model.dart';
import 'account_model.dart';
import 'project_model.dart';

class FinancialReportModel extends FinancialReport {
  const FinancialReportModel({
    required super.period,
    required super.summary,
    super.account,
    super.accountIncomes,
    super.accountExpenses,
    super.accountOutgoingTransits,
    super.accountIncomingTransits,
    super.project,
    super.projectAccounts,
    super.businessProjects,
  });

  factory FinancialReportModel.fromJson(Map<String, dynamic> json) {
    // Парсим период
    final periodJson = json['period'] as Map<String, dynamic>;
    final period = ReportPeriod(
      startDate: DateTime.parse(periodJson['startDate'] as String),
      endDate: DateTime.parse(periodJson['endDate'] as String),
    );

    // Парсим summary
    final summaryJson = json['summary'] as Map<String, dynamic>;
    final totalIncome = (summaryJson['totalIncomes'] as num?)?.toDouble() ?? 0.0;
    final totalExpense = (summaryJson['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    
    // Баланс = доходы - расходы
    final balance = totalIncome - totalExpense;
    
    // Если нет разделения на outgoing/incoming транзиты, используем общее значение
    // Если есть отдельные поля - используем их, иначе используем totalTransits для обоих
    final totalOutgoingTransits = (summaryJson['totalOutgoingTransits'] as num?)?.toDouble() ?? 
        (summaryJson['totalTransits'] as num?)?.toDouble() ?? 0.0;
    final totalIncomingTransits = (summaryJson['totalIncomingTransits'] as num?)?.toDouble() ?? 
        (summaryJson['totalTransits'] as num?)?.toDouble() ?? 0.0;
    
    final summary = ReportSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
      totalOutgoingTransits: totalOutgoingTransits,
      totalIncomingTransits: totalIncomingTransits,
    );

    // Режим 1: По конкретному счету (accountId)
    if (json['account'] != null) {
      final accountJson = json['account'] as Map<String, dynamic>;
      // businessId может отсутствовать в ответе отчета, используем пустую строку если нет
      final businessId = accountJson['businessId'] as String? ?? '';
      final account = AccountModel.fromJson(accountJson, businessId: businessId);

      final incomes = (json['incomes'] as List<dynamic>?)
              ?.map((e) => IncomeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Income>[];

      final expenses = (json['expenses'] as List<dynamic>?)
              ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <Expense>[];

      // Парсим outgoing транзиты (устанавливаем направление OUTGOING и relatedAccountId = toAccountId)
      final outgoingTransits = (json['outgoingTransits'] as List<dynamic>?)
              ?.map((e) {
            final transitJson = e as Map<String, dynamic>;
            final transit = TransitModel.fromJson(transitJson);
            return TransitModel(
              id: transit.id,
              businessId: transit.businessId,
              fromAccountId: transit.fromAccountId,
              toAccountId: transit.toAccountId,
              amount: transit.amount,
              article: transit.article,
              method: transit.method,
              comment: transit.comment,
              transactionDate: transit.transactionDate,
              direction: TransitDirection.OUTGOING,
              relatedAccountId: transit.toAccountId,
            );
          }).toList() ??
          <Transit>[];

      // Парсим incoming транзиты (устанавливаем направление INCOMING и relatedAccountId = fromAccountId)
      final incomingTransits = (json['incomingTransits'] as List<dynamic>?)
              ?.map((e) {
            final transitJson = e as Map<String, dynamic>;
            final transit = TransitModel.fromJson(transitJson);
            return TransitModel(
              id: transit.id,
              businessId: transit.businessId,
              fromAccountId: transit.fromAccountId,
              toAccountId: transit.toAccountId,
              amount: transit.amount,
              article: transit.article,
              method: transit.method,
              comment: transit.comment,
              transactionDate: transit.transactionDate,
              direction: TransitDirection.INCOMING,
              relatedAccountId: transit.fromAccountId,
            );
          }).toList() ??
          <Transit>[];

      return FinancialReportModel(
        period: period,
        summary: summary,
        account: account,
        accountIncomes: incomes,
        accountExpenses: expenses,
        accountOutgoingTransits: outgoingTransits,
        accountIncomingTransits: incomingTransits,
      );
    }

    // Режим 2: По проекту (projectId)
    if (json['project'] != null) {
      final projectJson = json['project'] as Map<String, dynamic>;
      final project = ProjectModel.fromJson(projectJson);

      final accountsJson = json['accounts'] as List<dynamic>? ?? [];
      // Получаем businessId из проекта, если есть, иначе используем пустую строку
      final projectBusinessId = projectJson['businessId'] as String? ?? '';
      final accounts = accountsJson.map((accountDataJson) {
        final accountData = accountDataJson as Map<String, dynamic>;
        final accountJson = accountData['account'] as Map<String, dynamic>;
        final accountBusinessId = accountJson['businessId'] as String? ?? projectBusinessId;
        final account = AccountModel.fromJson(accountJson, businessId: accountBusinessId);

        final incomes = (accountData['incomes'] as List<dynamic>?)
                ?.map((e) => IncomeModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <Income>[];

        final expenses = (accountData['expenses'] as List<dynamic>?)
                ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <Expense>[];

        // Парсим outgoing транзиты
        final outgoingTransits = (accountData['outgoingTransits'] as List<dynamic>?)
                ?.map((e) {
              final transitJson = e as Map<String, dynamic>;
              final transit = TransitModel.fromJson(transitJson);
              return TransitModel(
                id: transit.id,
                businessId: transit.businessId,
                fromAccountId: transit.fromAccountId,
                toAccountId: transit.toAccountId,
                amount: transit.amount,
                article: transit.article,
                method: transit.method,
                comment: transit.comment,
                transactionDate: transit.transactionDate,
                direction: TransitDirection.OUTGOING,
                relatedAccountId: transit.toAccountId,
              );
            }).toList() ??
            <Transit>[];

        // Парсим incoming транзиты
        final incomingTransits = (accountData['incomingTransits'] as List<dynamic>?)
                ?.map((e) {
              final transitJson = e as Map<String, dynamic>;
              final transit = TransitModel.fromJson(transitJson);
              return TransitModel(
                id: transit.id,
                businessId: transit.businessId,
                fromAccountId: transit.fromAccountId,
                toAccountId: transit.toAccountId,
                amount: transit.amount,
                article: transit.article,
                method: transit.method,
                comment: transit.comment,
                transactionDate: transit.transactionDate,
                direction: TransitDirection.INCOMING,
                relatedAccountId: transit.fromAccountId,
              );
            }).toList() ??
            <Transit>[];

        return AccountReportData(
          account: account,
          incomes: incomes,
          expenses: expenses,
          outgoingTransits: outgoingTransits,
          incomingTransits: incomingTransits,
        );
      }).toList();

      return FinancialReportModel(
        period: period,
        summary: summary,
        project: project,
        projectAccounts: accounts,
      );
    }

    // Режим 3: По всему бизнесу (без фильтров)
    if (json['projects'] != null) {
      final projectsJson = json['projects'] as List<dynamic>? ?? [];
      final projects = projectsJson.map((projectDataJson) {
        final projectData = projectDataJson as Map<String, dynamic>;
        final project = ProjectModel.fromJson(projectData['project'] as Map<String, dynamic>);

        final accountsJson = projectData['accounts'] as List<dynamic>? ?? [];
        // Получаем businessId из проекта
        final projectBusinessId = projectData['project']?['businessId'] as String? ?? '';
        final accounts = accountsJson.map((accountDataJson) {
          final accountData = accountDataJson as Map<String, dynamic>;
          final accountJson = accountData['account'] as Map<String, dynamic>;
          final accountBusinessId = accountJson['businessId'] as String? ?? projectBusinessId;
          final account = AccountModel.fromJson(accountJson, businessId: accountBusinessId);

          final incomes = (accountData['incomes'] as List<dynamic>?)
                  ?.map((e) => IncomeModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              <Income>[];

          final expenses = (accountData['expenses'] as List<dynamic>?)
                  ?.map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              <Expense>[];

          // Парсим outgoing транзиты
          final outgoingTransits = (accountData['outgoingTransits'] as List<dynamic>?)
                  ?.map((e) {
                final transitJson = e as Map<String, dynamic>;
                final transit = TransitModel.fromJson(transitJson);
                return TransitModel(
                  id: transit.id,
                  businessId: transit.businessId,
                  fromAccountId: transit.fromAccountId,
                  toAccountId: transit.toAccountId,
                  amount: transit.amount,
                  article: transit.article,
                  method: transit.method,
                  comment: transit.comment,
                  transactionDate: transit.transactionDate,
                  direction: TransitDirection.OUTGOING,
                  relatedAccountId: transit.toAccountId,
                );
              }).toList() ??
              <Transit>[];

          // Парсим incoming транзиты
          final incomingTransits = (accountData['incomingTransits'] as List<dynamic>?)
                  ?.map((e) {
                final transitJson = e as Map<String, dynamic>;
                final transit = TransitModel.fromJson(transitJson);
                return TransitModel(
                  id: transit.id,
                  businessId: transit.businessId,
                  fromAccountId: transit.fromAccountId,
                  toAccountId: transit.toAccountId,
                  amount: transit.amount,
                  article: transit.article,
                  method: transit.method,
                  comment: transit.comment,
                  transactionDate: transit.transactionDate,
                  direction: TransitDirection.INCOMING,
                  relatedAccountId: transit.fromAccountId,
                );
              }).toList() ??
              <Transit>[];

          return AccountReportData(
            account: account,
            incomes: incomes,
            expenses: expenses,
            outgoingTransits: outgoingTransits,
            incomingTransits: incomingTransits,
          );
        }).toList();

        return ProjectReportData(
          project: project,
          accounts: accounts,
        );
      }).toList();

      return FinancialReportModel(
        period: period,
        summary: summary,
        businessProjects: projects,
      );
    }

    // Если ничего не найдено, возвращаем пустой отчет
    return FinancialReportModel(
      period: period,
      summary: summary,
    );
  }
}

