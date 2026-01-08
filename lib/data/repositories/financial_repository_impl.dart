import 'package:dartz/dartz.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/income_category.dart';
import '../../domain/entities/income.dart';
import '../../domain/entities/expense.dart';
import '../../domain/entities/transit.dart';
import '../../domain/entities/financial_report.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/financial_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/financial_remote_datasource.dart';
import '../repositories/repository_impl.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/transit_model.dart';
import '../models/account_model.dart';
import '../datasources/financial_remote_datasource_impl.dart' show ValidationException;

/// Реализация репозитория финансового блока
class FinancialRepositoryImpl extends RepositoryImpl implements FinancialRepository {
  final FinancialRemoteDataSource remoteDataSource;

  FinancialRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, ApprovalTemplate>> getIncomeForm({
    required String businessId,
  }) async {
    try {
      final formModel = await remoteDataSource.getIncomeForm(businessId: businessId);
      return Right(formModel.toApprovalTemplate());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApprovalTemplate>> getExpenseForm({
    required String businessId,
  }) async {
    try {
      final formModel = await remoteDataSource.getExpenseForm(businessId: businessId);
      return Right(formModel.toApprovalTemplate());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ApprovalTemplate>> getTransitForm({
    required String businessId,
  }) async {
    try {
      final formModel = await remoteDataSource.getTransitForm(businessId: businessId);
      return Right(formModel.toApprovalTemplate());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<IncomeCategory>>> getIncomeCategories({
    required String businessId,
  }) async {
    try {
      final categories = await remoteDataSource.getIncomeCategories(businessId: businessId);
      return Right(categories);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Income>> createIncome(Income income) async {
    try {
      final model = IncomeModel(
        businessId: income.businessId,
        projectId: income.projectId,
        accountId: income.accountId,
        amount: income.amount,
        currency: income.currency,
        article: income.article,
        periodicity: income.periodicity,
        categoryId: income.categoryId,
        serviceId: income.serviceId,
        paymentMethod: income.paymentMethod,
        comment: income.comment,
        transactionDate: income.transactionDate,
      );
      final result = await remoteDataSource.createIncome(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Expense>> createExpense(Expense expense) async {
    try {
      final model = ExpenseModel(
        businessId: expense.businessId,
        projectId: expense.projectId,
        accountId: expense.accountId,
        amount: expense.amount,
        currency: expense.currency,
        category: expense.category,
        articleId: expense.articleId,
        periodicity: expense.periodicity,
        serviceId: expense.serviceId,
        paymentMethod: expense.paymentMethod,
        comment: expense.comment,
        transactionDate: expense.transactionDate,
      );
      final result = await remoteDataSource.createExpense(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transit>> createTransit(Transit transit) async {
    try {
      final model = TransitModel(
        businessId: transit.businessId,
        fromAccountId: transit.fromAccountId,
        toAccountId: transit.toAccountId,
        amount: transit.amount,
        article: transit.article,
        method: transit.method,
        comment: transit.comment,
        transactionDate: transit.transactionDate,
      );
      final result = await remoteDataSource.createTransit(model);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FinancialReport>> getFinancialReport({
    required String businessId,
    required DateTime startDate,
    required DateTime endDate,
    String? projectId,
    String? accountId,
  }) async {
    try {
      final report = await remoteDataSource.getFinancialReport(
        businessId: businessId,
        startDate: startDate.toIso8601String(),
        endDate: endDate.toIso8601String(),
        projectId: projectId,
        accountId: accountId,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Account>>> getAccounts({
    required String businessId,
    String? projectId,
    String? accountType,
  }) async {
    try {
      final accounts = await remoteDataSource.getAccounts(
        businessId: businessId,
        projectId: projectId,
        accountType: accountType,
      );
      return Right(accounts);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Account>> createAccount(Account account) async {
    try {
      final model = AccountModel(
        id: account.id,
        name: account.name,
        businessId: account.businessId,
        projectId: account.projectId,
        balance: account.balance,
        currency: account.currency,
        type: account.type,
        description: account.description,
        isActive: account.isActive,
        createdAt: account.createdAt,
        updatedAt: account.updatedAt,
      );
      final result = await remoteDataSource.createAccount(model);
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
