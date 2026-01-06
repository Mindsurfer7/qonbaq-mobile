import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../domain/entities/time_slot.dart';
import '../datasources/time_slot_remote_datasource.dart';
import '../models/time_slot_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для тайм-слотов
class TimeSlotRemoteDataSourceImpl extends TimeSlotRemoteDataSource {
  final ApiClient apiClient;

  TimeSlotRemoteDataSourceImpl({required this.apiClient});

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

  String _statusToString(TimeSlotStatus? status) {
    if (status == null) return '';
    switch (status) {
      case TimeSlotStatus.available:
        return 'AVAILABLE';
      case TimeSlotStatus.booked:
        return 'BOOKED';
      case TimeSlotStatus.unavailable:
        return 'UNAVAILABLE';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  @override
  Future<List<TimeSlotModel>> getTimeSlots({
    String? employmentId,
    String? resourceId,
    String? serviceId,
    DateTime? date,
    DateTime? from,
    DateTime? to,
    TimeSlotStatus? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (employmentId != null) queryParams['employmentId'] = employmentId;
      if (resourceId != null) queryParams['resourceId'] = resourceId;
      if (serviceId != null) queryParams['serviceId'] = serviceId;
      if (date != null) {
        // Форматируем дату как YYYY-MM-DD или ISO8601
        queryParams['date'] = date.toIso8601String();
      }
      if (from != null) queryParams['from'] = _formatDateTime(from);
      if (to != null) queryParams['to'] = _formatDateTime(to);
      if (status != null) queryParams['status'] = _statusToString(status);

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';

      final response = await apiClient.get(
        '/api/time-slots$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final slotsList = data as List<dynamic>;
            return slotsList
                .map((item) => TimeSlotModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<TimeSlotModel> getTimeSlotById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/time-slots/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => TimeSlotModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Тайм-слот не найден');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<TimeSlotModel> createTimeSlot(TimeSlotModel timeSlot) async {
    try {
      final body = timeSlot.toCreateJson();
      final response = await apiClient.post(
        '/api/time-slots',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => TimeSlotModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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
  Future<List<TimeSlotModel>> generateTimeSlots(Map<String, dynamic> params) async {
    try {
      final response = await apiClient.post(
        '/api/time-slots/generate',
        headers: _getAuthHeaders(),
        body: params,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final slotsList = data as List<dynamic>;
            return slotsList
                .map((item) => TimeSlotModel.fromJson(item as Map<String, dynamic>))
                .toList();
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
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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
  Future<TimeSlotModel> updateTimeSlot(String id, TimeSlotModel timeSlot) async {
    try {
      final body = timeSlot.toUpdateJson();
      final response = await apiClient.patch(
        '/api/time-slots/$id',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => TimeSlotModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Тайм-слот не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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
  Future<void> deleteTimeSlot(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/time-slots/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Тайм-слот не найден');
      } else {
        throw Exception(ErrorHandler.getErrorMessage(response.statusCode, response.body));
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

