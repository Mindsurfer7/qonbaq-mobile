import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/department_remote_datasource.dart';
import '../models/department_model.dart';

/// Реализация удаленного источника данных для подразделений
class DepartmentRemoteDataSourceImpl extends DepartmentRemoteDataSource {
  final ApiClient apiClient;

  DepartmentRemoteDataSourceImpl({required this.apiClient});

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
  Future<List<DepartmentModel>> getBusinessDepartments(
    String businessId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/departments/business/$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final departmentsList = json['departments'] as List<dynamic>? ??
            (json['data'] as List<dynamic>?) ??
            json['items'] as List<dynamic>? ??
            (json as List<dynamic>);
        return departmentsList
            .map(
              (item) => DepartmentModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
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
  Future<DepartmentModel> getDepartmentById(String departmentId) async {
    try {
      final response = await apiClient.get(
        '/api/departments/$departmentId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API возвращает { "department": {...} }
        final departmentJson = json['department'] as Map<String, dynamic>? ?? json;
        return DepartmentModel.fromJson(departmentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
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
  Future<DepartmentModel> createDepartment(
    DepartmentModel department,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/departments',
        headers: _getAuthHeaders(),
        body: department.toCreateJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API возвращает { "department": {...} }
        final departmentJson = json['department'] as Map<String, dynamic>? ?? json;
        return DepartmentModel.fromJson(departmentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка валидации';
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
  Future<DepartmentModel> updateDepartment(
    String departmentId,
    DepartmentModel department,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/departments/$departmentId',
        headers: _getAuthHeaders(),
        body: department.toUpdateJson(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API возвращает { "department": {...} }
        final departmentJson = json['department'] as Map<String, dynamic>? ?? json;
        return DepartmentModel.fromJson(departmentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка валидации';
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
  Future<void> deleteDepartment(String departmentId) async {
    try {
      final response = await apiClient.delete(
        '/api/departments/$departmentId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
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
  Future<List<Map<String, dynamic>>> getDepartmentEmployees(
    String departmentId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/departments/$departmentId/employees',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final employeesList = json['employees'] as List<dynamic>? ??
            (json['data'] as List<dynamic>?) ??
            json['items'] as List<dynamic>? ??
            (json as List<dynamic>);
        return employeesList
            .map((item) => item as Map<String, dynamic>)
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
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
  Future<DepartmentModel> setDepartmentManager(
    String departmentId,
    String managerId,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/departments/$departmentId/manager',
        headers: _getAuthHeaders(),
        body: {'managerId': managerId},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API возвращает { "department": {...} }
        final departmentJson = json['department'] as Map<String, dynamic>? ?? json;
        return DepartmentModel.fromJson(departmentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка валидации';
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
  Future<DepartmentModel> removeDepartmentManager(
    String departmentId,
  ) async {
    try {
      final response = await apiClient.delete(
        '/api/departments/$departmentId/manager',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // API возвращает { "department": {...} }
        final departmentJson = json['department'] as Map<String, dynamic>? ?? json;
        return DepartmentModel.fromJson(departmentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
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
  Future<void> assignEmployeeToDepartment(
    String departmentId,
    String employmentId,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/departments/$departmentId/employee',
        headers: _getAuthHeaders(),
        body: {'employmentId': employmentId},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение или сотрудник не найдены');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка валидации';
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
  Future<void> removeEmployeeFromDepartment(
    String departmentId,
    String employmentId,
  ) async {
    try {
      // DELETE с body - используем http.Request напрямую
      final url = Uri.parse('${apiClient.baseUrl}/api/departments/$departmentId/employee');
      final headers = _getAuthHeaders();
      final body = jsonEncode({'employmentId': employmentId});
      
      final request = http.Request('DELETE', url);
      request.headers.addAll(headers);
      request.body = body;
      
      final streamedResponse = await apiClient.client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение или сотрудник не найдены');
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
  Future<void> assignEmployeesToDepartment(
    String departmentId,
    List<String> employmentIds,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/departments/$departmentId/employees',
        headers: _getAuthHeaders(),
        body: {'employmentIds': employmentIds},
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Подразделение не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['message'] as String? ?? 'Ошибка валидации';
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
  Future<List<DepartmentModel>> getBusinessDepartmentsTree(
    String businessId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/departments/business/$businessId/tree',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final departmentsList = json['departments'] as List<dynamic>? ??
            (json['data'] as List<dynamic>?) ??
            (json as List<dynamic>);
        return departmentsList
            .map(
              (item) => DepartmentModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
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
}

