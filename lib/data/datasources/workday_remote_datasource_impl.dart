import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../models/workday_model.dart';
import '../models/validation_error.dart';
import '../models/api_response.dart';
import 'workday_remote_datasource.dart';

/// Реализация удаленного источника данных для рабочего дня
class WorkDayRemoteDataSourceImpl extends WorkDayRemoteDataSource {
  final ApiClient apiClient;

  WorkDayRemoteDataSourceImpl({required this.apiClient});

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
  Future<WorkDayModel> startWorkDay(String businessId) async {
    try {
      final response = await apiClient.post(
        '/api/workday/start',
        headers: _getAuthHeaders(),
        body: {'businessId': businessId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final workDayJson = data as Map<String, dynamic>;
            // Добавляем businessId, если его нет в ответе
            if (!workDayJson.containsKey('businessId')) {
              workDayJson['businessId'] = businessId;
            }
            return WorkDayModel.fromJson(workDayJson);
          },
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
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при начале рабочего дня';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is ValidationException) {
            rethrow;
          }
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при начале рабочего дня');
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
  Future<WorkDayModel> endWorkDay(String businessId) async {
    try {
      final response = await apiClient.post(
        '/api/workday/end',
        headers: _getAuthHeaders(),
        body: {'businessId': businessId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final workDayJson = data as Map<String, dynamic>;
            // Добавляем businessId, если его нет в ответе
            if (!workDayJson.containsKey('businessId')) {
              workDayJson['businessId'] = businessId;
            }
            return WorkDayModel.fromJson(workDayJson);
          },
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
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при завершении рабочего дня';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is ValidationException) {
            rethrow;
          }
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при завершении рабочего дня');
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
  Future<WorkDayModel> markAbsent(String businessId, String reason) async {
    try {
      final response = await apiClient.post(
        '/api/workday/absent',
        headers: _getAuthHeaders(),
        body: {
          'businessId': businessId,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final workDayJson = data as Map<String, dynamic>;
            // Добавляем businessId, если его нет в ответе
            if (!workDayJson.containsKey('businessId')) {
              workDayJson['businessId'] = businessId;
            }
            return WorkDayModel.fromJson(workDayJson);
          },
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
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при отметке отсутствия';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is ValidationException) {
            rethrow;
          }
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при отметке отсутствия');
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
  Future<WorkDayModel?> getTodayStatus(String businessId) async {
    try {
      final response = await apiClient.get(
        '/api/workday/status?businessId=$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final workDayJson = data as Map<String, dynamic>;
            // Если есть рабочий день, возвращаем его
            if (workDayJson.containsKey('id')) {
              // Добавляем businessId, если его нет в ответе
              if (!workDayJson.containsKey('businessId')) {
                workDayJson['businessId'] = businessId;
              }
              return WorkDayModel.fromJson(workDayJson);
            }
            // Если рабочего дня нет, возвращаем null
            return null;
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        // Если рабочего дня нет, возвращаем null
        return null;
      } else {
        // Пытаемся извлечь сообщение из поля error
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при получении статуса рабочего дня';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при получении статуса рабочего дня');
        }
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<WorkDayStatisticsModel> getStatistics(
      String businessId, String month) async {
    try {
      final response = await apiClient.get(
        '/api/workday/statistics?businessId=$businessId&month=$month',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => WorkDayStatisticsModel.fromJson(
            data as Map<String, dynamic>,
            businessId: businessId,
          ),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        // Пытаемся извлечь сообщение из поля error
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при получении статистики рабочего дня';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при получении статистики рабочего дня');
        }
      }
    } catch (e) {
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
  String toString() => validationResponse.message ?? validationResponse.error;
}

