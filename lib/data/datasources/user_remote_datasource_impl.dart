import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';
import '../models/business_model.dart';
import '../models/user_profile_model.dart';
import '../models/employee_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для пользователей
class UserRemoteDataSourceImpl extends UserRemoteDataSource {
  final ApiClient apiClient;

  UserRemoteDataSourceImpl({required this.apiClient});

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
  Future<UserModel> getUserById(String id) async {
    // Реализация будет добавлена при необходимости
    throw UnimplementedError('getUserById not implemented');
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    // Реализация будет добавлена при необходимости
    throw UnimplementedError('getAllUsers not implemented');
  }

  @override
  Future<UserModel> createUser(UserModel user) async {
    // Реализация будет добавлена при необходимости
    throw UnimplementedError('createUser not implemented');
  }

  @override
  Future<List<BusinessModel>> getUserBusinesses() async {
    try {
      final response = await apiClient.get(
        '/api/user/businesses',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final businessesList = data as List<dynamic>;
            return businessesList
                .map((item) => BusinessModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<UserProfileModel> getUserProfile({String? businessId}) async {
    try {
      String endpoint = '/api/user/profile';
      if (businessId != null) {
        endpoint += '?businessId=$businessId';
      }

      final response = await apiClient.get(
        endpoint,
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => UserProfileModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка запроса';
        throw Exception(message);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<EmployeeModel>> getBusinessEmployees(String businessId) async {
    try {
      final response = await apiClient.get(
        '/api/user/business/$businessId/employees',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final employeesList = data as List<dynamic>;
            return employeesList
                .map((item) => EmployeeModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этой компании');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<BusinessModel> createBusiness(BusinessModel business) async {
    try {
      final response = await apiClient.post(
        '/api/businesses',
        headers: _getAuthHeaders(),
        body: business.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => BusinessModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        // Пытаемся извлечь сообщение из поля error
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final errorMessage = json['error'] as String? ?? 
              json['message'] as String? ?? 
              'Ошибка при создании бизнеса';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is ValidationException) {
            rethrow;
          }
          throw Exception('Ошибка при создании бизнеса');
        }
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
  Future<BusinessModel> updateBusiness(String id, BusinessModel business) async {
    try {
      final response = await apiClient.patch(
        '/api/businesses/$id',
        headers: _getAuthHeaders(),
        body: business.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => BusinessModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = ErrorHandler.getErrorMessage(
          response.statusCode,
          response.body,
        );
        throw Exception(errorMessage);
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
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() =>
      validationResponse.message ?? validationResponse.error;
}
