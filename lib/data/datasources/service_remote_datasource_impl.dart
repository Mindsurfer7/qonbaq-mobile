import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../datasources/service_remote_datasource.dart';
import '../models/service_model.dart';
import '../models/service_assignment_model.dart';
import '../models/api_response.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для услуг
class ServiceRemoteDataSourceImpl extends ServiceRemoteDataSource {
  final ApiClient apiClient;

  ServiceRemoteDataSourceImpl({required this.apiClient});

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
  Future<List<ServiceModel>> getBusinessServices(
    String businessId, {
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/businesses/$businessId/services$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final servicesList = data as List<dynamic>;
            return servicesList
                .map((item) => ServiceModel.fromJson(item as Map<String, dynamic>))
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
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/services/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ServiceModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Услуга не найдена');
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
  Future<ServiceModel> createService(
    String businessId,
    ServiceModel service, {
    List<String>? employmentIds,
  }) async {
    try {
      final body = service.toCreateJson(employmentIds: employmentIds);
      final response = await apiClient.post(
        '/api/businesses/$businessId/services',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ServiceModel.fromJson(data as Map<String, dynamic>),
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
  Future<ServiceModel> updateService(String id, ServiceModel service) async {
    try {
      final body = service.toUpdateJson();
      final response = await apiClient.patch(
        '/api/services/$id',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ServiceModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Услуга не найдена');
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
  Future<void> deleteService(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/services/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Услуга не найдена');
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
  Future<List<ServiceAssignmentModel>> getServiceAssignments(
    String serviceId, {
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }
      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/services/$serviceId/assignments$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final assignmentsList = data as List<dynamic>;
            return assignmentsList
                .map((item) => ServiceAssignmentModel.fromJson(item as Map<String, dynamic>))
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
  Future<ServiceAssignmentModel> createAssignment(
    String serviceId, {
    String? employmentId,
    String? resourceId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (employmentId != null) {
        body['employmentId'] = employmentId;
      }
      if (resourceId != null) {
        body['resourceId'] = resourceId;
      }

      final response = await apiClient.post(
        '/api/services/$serviceId/assignments',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ServiceAssignmentModel.fromJson(data as Map<String, dynamic>),
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
  Future<ServiceAssignmentModel> updateAssignment(
    String id, {
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (isActive != null) {
        body['isActive'] = isActive;
      }

      final response = await apiClient.patch(
        '/api/assignments/$id',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ServiceAssignmentModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Назначение не найдено');
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
  Future<void> deleteAssignment(String id) async {
    try {
      final response = await apiClient.delete(
        '/api/assignments/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Назначение не найдено');
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

