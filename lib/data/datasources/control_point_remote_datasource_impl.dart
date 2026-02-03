import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/control_point_remote_datasource.dart';
import '../models/control_point_model.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для точек контроля
class ControlPointRemoteDataSourceImpl
    extends ControlPointRemoteDataSource {
  final ApiClient apiClient;

  ControlPointRemoteDataSourceImpl({required this.apiClient});

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
  Future<ApiResponse<List<ControlPointModel>>> getControlPoints({
    String? businessId,
    String? assignedTo,
    bool? isActive,
    int? page,
    int? limit,
    bool? showAll,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) queryParams['businessId'] = businessId;
      if (assignedTo != null) queryParams['assignedTo'] = assignedTo;
      if (isActive != null) queryParams['isActive'] = isActive.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (showAll != null) queryParams['showAll'] = showAll.toString();

      final queryString = queryParams.isEmpty
          ? ''
          : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/control-points$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Отладочная информация
        print('ControlPoints API response: status=${response.statusCode}');
        print('ControlPoints API response body keys: ${json.keys.toList()}');
        if (json['data'] != null) {
          final dataList = json['data'] as List<dynamic>;
          print('ControlPoints API data count: ${dataList.length}');
          if (dataList.isNotEmpty) {
            print('ControlPoints API first item keys: ${(dataList[0] as Map<String, dynamic>).keys.toList()}');
          }
        }
        
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => (data as List<dynamic>)
              .map((item) => ControlPointModel.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList(),
        );
        
        print('ControlPoints parsed: ${apiResponse.data.length} items');
        return apiResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа');
      } else {
        // Пытаемся извлечь сообщение из поля error
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при получении списка точек контроля';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при получении списка точек контроля');
        }
      }
    } catch (e) {
      if (e is FormatException) {
        // Детальная информация об ошибке парсинга
        throw Exception('Ошибка парсинга данных: ${e.message}');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ControlPointModel> getControlPointById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/control-points/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ControlPointModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Точка контроля не найдена');
      } else {
        // Пытаемся извлечь сообщение из поля error
        try {
          final json = jsonDecode(response.body) as Map<String, dynamic>?;
          final errorMessage = json?['error'] as String? ?? 
              json?['message'] as String? ?? 
              'Ошибка при получении точки контроля';
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && !(e is FormatException)) {
            rethrow;
          }
          throw Exception('Ошибка при получении точки контроля');
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
