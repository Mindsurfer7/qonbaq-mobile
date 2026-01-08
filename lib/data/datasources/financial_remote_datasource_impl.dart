import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/financial_remote_datasource.dart';
import '../models/financial_form_model.dart';
import '../models/api_response.dart';
import '../models/income_category_model.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/transit_model.dart';
import '../models/financial_report_model.dart';
import '../models/account_model.dart';
import '../models/validation_error.dart';

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() =>
      validationResponse.message ?? validationResponse.error;
}

/// Реализация удаленного источника данных для финансового блока
class FinancialRemoteDataSourceImpl extends FinancialRemoteDataSource {
  final ApiClient apiClient;

  FinancialRemoteDataSourceImpl({required this.apiClient});

  /// Парсит сообщение об ошибке из body ответа
  String _parseErrorMessage(String body, String defaultMessage) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }

  Map<String, String> _getAuthHeaders() {
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<FinancialFormModel> getIncomeForm({
    required String businessId,
  }) async {
    final response = await apiClient.get(
      '/api/financial/forms/income?businessId=$businessId',
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => FinancialFormModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении формы прихода: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<FinancialFormModel> getExpenseForm({
    required String businessId,
  }) async {
    final response = await apiClient.get(
      '/api/financial/forms/expense?businessId=$businessId',
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => FinancialFormModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении формы расхода: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<FinancialFormModel> getTransitForm({
    required String businessId,
  }) async {
    final response = await apiClient.get(
      '/api/financial/forms/transit?businessId=$businessId',
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => FinancialFormModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении формы транзита: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<List<IncomeCategoryModel>> getIncomeCategories({
    required String businessId,
  }) async {
    final response = await apiClient.get(
      '/api/financial/income-categories?businessId=$businessId',
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => (data as List<dynamic>)
            .map((e) => IncomeCategoryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении категорий доходов: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<IncomeModel> createIncome(IncomeModel income) async {
    final response = await apiClient.post(
      '/api/financial/incomes',
      headers: _getAuthHeaders(),
      body: jsonEncode(income.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => IncomeModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при создании прихода: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    final response = await apiClient.post(
      '/api/financial/expenses',
      headers: _getAuthHeaders(),
      body: jsonEncode(expense.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => ExpenseModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при создании расхода: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<TransitModel> createTransit(TransitModel transit) async {
    final response = await apiClient.post(
      '/api/financial/transits',
      headers: _getAuthHeaders(),
      body: jsonEncode(transit.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => TransitModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при создании транзита: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<FinancialReportModel> getFinancialReport({
    required String businessId,
    required String startDate,
    required String endDate,
    String? projectId,
  }) async {
    var url = '/api/financial/reports?businessId=$businessId&startDate=$startDate&endDate=$endDate';
    if (projectId != null) {
      url += '&projectId=$projectId';
    }

    final response = await apiClient.get(
      url,
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => FinancialReportModel.fromJson(data as Map<String, dynamic>),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении отчета: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<List<AccountModel>> getAccounts({
    required String businessId,
    String? projectId,
    String? accountType,
  }) async {
    var url = '/api/financial/accounts?businessId=$businessId';
    if (projectId != null) {
      url += '&projectId=$projectId';
    }
    if (accountType != null) {
      url += '&accountType=$accountType';
    }

    final response = await apiClient.get(
      url,
      headers: _getAuthHeaders(),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final apiResponse = ApiResponse.fromJson(
        json,
        (data) => (data as List<dynamic>)
            .map((e) => AccountModel.fromJson(
                  e as Map<String, dynamic>,
                  businessId: businessId,
                ))
            .toList(),
      );
      return apiResponse.data;
    } else {
      final errorMessage = _parseErrorMessage(
        response.body,
        'Ошибка при получении списка счетов: ${response.statusCode}',
      );
      throw Exception(errorMessage);
    }
  }

  @override
  Future<AccountModel> createAccount(AccountModel account) async {
    try {
      final response = await apiClient.post(
        '/api/financial/accounts',
        headers: _getAuthHeaders(),
        body: account.toCreateJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => AccountModel.fromJson(
            data as Map<String, dynamic>,
            businessId: account.businessId,
          ),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else if (response.statusCode == 403) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Нет доступа к этому бизнесу',
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка при создании счета: ${response.statusCode}',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }
}
