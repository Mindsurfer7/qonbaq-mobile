import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../models/workday_model.dart';
import '../models/validation_error.dart';
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
        // Извлекаем workDay из обертки {success: true, workDay: {...}}
        final workDayJson = json['workDay'] as Map<String, dynamic>? ?? json;
        // Добавляем businessId, если его нет в ответе
        if (!workDayJson.containsKey('businessId')) {
          workDayJson['businessId'] = businessId;
        }
        return WorkDayModel.fromJson(workDayJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
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
        // Извлекаем workDay из обертки {success: true, workDay: {...}}
        final workDayJson = json['workDay'] as Map<String, dynamic>? ?? json;
        // Добавляем businessId, если его нет в ответе
        if (!workDayJson.containsKey('businessId')) {
          workDayJson['businessId'] = businessId;
        }
        return WorkDayModel.fromJson(workDayJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
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
        // Извлекаем workDay из обертки {success: true, workDay: {...}}
        final workDayJson = json['workDay'] as Map<String, dynamic>? ?? json;
        // Добавляем businessId, если его нет в ответе
        if (!workDayJson.containsKey('businessId')) {
          workDayJson['businessId'] = businessId;
        }
        return WorkDayModel.fromJson(workDayJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
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
        // Извлекаем workDay из обертки, если есть
        final workDayJson = json['workDay'] as Map<String, dynamic>? ?? json;
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
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        // Если рабочего дня нет, возвращаем null
        return null;
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
  Future<WorkDayStatisticsModel> getStatistics(
      String businessId, String month) async {
    try {
      final response = await apiClient.get(
        '/api/workday/statistics?businessId=$businessId&month=$month',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkDayStatisticsModel.fromJson(json, businessId: businessId);
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
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() => validationResponse.message ?? validationResponse.error;
}

