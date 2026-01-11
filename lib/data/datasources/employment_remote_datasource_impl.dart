import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/employment_remote_datasource.dart';
import '../models/employment_with_role_model.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для трудоустройств
class EmploymentRemoteDataSourceImpl extends EmploymentRemoteDataSource {
  final ApiClient apiClient;

  EmploymentRemoteDataSourceImpl({required this.apiClient});

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
  Future<List<EmploymentWithRoleModel>> getBusinessEmploymentsWithRoles(
    String businessId,
  ) async {
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
                .map(
                  (item) => _convertEmployeeToEmploymentWithRole(
                    item as Map<String, dynamic>,
                    businessId,
                  ),
                )
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этой компании');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка сервера: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  /// Конвертирует ответ от /api/user/business/{businessId}/employees в EmploymentWithRoleModel
  EmploymentWithRoleModel _convertEmployeeToEmploymentWithRole(
    Map<String, dynamic> json,
    String businessId,
  ) {
    // Структура ответа от существующего API:
    // {
    //   "user": {...},
    //   "employment": {...},
    //   "business": {...}
    // }

    final user = json['user'] as Map<String, dynamic>? ?? json;
    final employment = json['employment'] as Map<String, dynamic>?;
    final business = json['business'] as Map<String, dynamic>?;

    return EmploymentWithRoleModel(
      id: employment?['id'] as String? ?? '',
      userId: user['id'] as String,
      businessId: businessId,
      position: employment?['position'] as String?,
      orgPosition: employment?['orgPosition'] as String?,
      roleCode: employment?['roleCode'] as String?, // Может отсутствовать в текущем API
      user: EmploymentUserModel(
        id: user['id'] as String,
        email: user['email'] as String,
        firstName: user['firstName'] as String?,
        lastName: user['lastName'] as String?,
        patronymic: user['patronymic'] as String?,
      ),
      business: EmploymentBusinessModel(
        id: business?['id'] as String? ?? businessId,
        name: business?['name'] as String? ?? '',
      ),
      role: () {
        final roleCode = employment?['roleCode'] as String?;
        return roleCode != null
            ? EmploymentRoleModel(
                code: roleCode,
                name: _getRoleName(roleCode),
              )
            : null;
      }(),
    );
  }

  /// Возвращает название роли по коду
  String _getRoleName(String roleCode) {
    const roleNames = {
      'ACCOUNTANT': 'Бухгалтер',
      'LAWYER': 'Юрист',
      'SALES_MANAGER': 'Менеджер продаж',
      'PURCHASE_MANAGER': 'Менеджер закупа',
      'SECRETARY': 'Секретарь',
      'MARKETER': 'Маркетолог',
      'FINANCE_MANAGER': 'Менеджер по финансам',
      'LOGISTICIAN': 'Логист',
    };
    return roleNames[roleCode] ?? roleCode;
  }

  @override
  Future<EmploymentWithRoleModel> updateEmploymentRole(
    String employmentId,
    String? roleCode,
  ) async {
    try {
      final response = await apiClient.patch(
        '/api/employments/$employmentId/role',
        headers: _getAuthHeaders(),
        body: {'roleCode': roleCode},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => EmploymentWithRoleModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка валидации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этой компании');
      } else if (response.statusCode == 404) {
        throw Exception('Трудоустройство не найдено');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка сервера: ${response.statusCode}';
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
  Future<List<EmploymentWithRoleModel>> assignEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/employments/roles',
        headers: _getAuthHeaders(),
        body: employmentsRoles,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final employmentsList = data as List<dynamic>;
            return employmentsList
                .map(
                  (item) => EmploymentWithRoleModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка валидации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этой компании');
      } else if (response.statusCode == 404) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Некоторые трудоустройства не найдены';
        throw Exception(errorMessage);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка сервера: ${response.statusCode}';
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
  Future<List<EmploymentWithRoleModel>> updateEmploymentsRoles(
    Map<String, String?> employmentsRoles,
  ) async {
    try {
      final response = await apiClient.patch(
        '/api/employments/roles',
        headers: _getAuthHeaders(),
        body: employmentsRoles,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final employmentsList = data as List<dynamic>;
            return employmentsList
                .map(
                  (item) => EmploymentWithRoleModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка валидации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этой компании');
      } else if (response.statusCode == 404) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Некоторые трудоустройства не найдены';
        throw Exception(errorMessage);
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = json['error'] as String? ?? 'Ошибка сервера: ${response.statusCode}';
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