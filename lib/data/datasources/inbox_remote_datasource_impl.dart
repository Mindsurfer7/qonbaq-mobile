import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../datasources/inbox_remote_datasource.dart';
import '../models/inbox_item_model.dart';
import '../models/validation_error.dart';
import '../models/api_response.dart';

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() =>
      validationResponse.message ?? validationResponse.error;
}

/// Реализация удаленного источника данных для Inbox Items
class InboxRemoteDataSourceImpl extends InboxRemoteDataSource {
  final ApiClient apiClient;

  InboxRemoteDataSourceImpl({required this.apiClient});

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
  Future<InboxItemModel> createInboxItem(InboxItemModel inboxItem) async {
    try {
      final response = await apiClient.post(
        '/api/inbox',
        headers: _getAuthHeaders(),
        body: inboxItem.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => InboxItemModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
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

  @override
  Future<InboxItemModel> getInboxItemById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/inbox/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => InboxItemModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Inbox item не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<InboxItemModel>> getInboxItems({
    String? businessId,
    bool? isArchived,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) queryParams['businessId'] = businessId;
      if (isArchived != null) {
        queryParams['isArchived'] = isArchived.toString();
      }
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (sortBy != null) queryParams['sortBy'] = sortBy;
      if (sortOrder != null) queryParams['sortOrder'] = sortOrder;

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/inbox$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final itemsList = data as List<dynamic>;
            return itemsList
                .map((item) =>
                    InboxItemModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<InboxItemModel> updateInboxItem(
    String id,
    InboxItemModel inboxItem,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/inbox/$id',
        headers: _getAuthHeaders(),
        body: inboxItem.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => InboxItemModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Inbox item не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
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

  @override
  Future<void> deleteInboxItem(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/inbox/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Inbox item не найден');
      } else {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }
}

