import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/user_actions_needed_model.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для уведомлений
class NotificationRemoteDataSourceImpl extends NotificationRemoteDataSource {
  final ApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

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
  Future<ApiResponse<UserActionsNeededModel>> getNotifications({
    required String businessId,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/notifications?businessId=$businessId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => UserActionsNeededModel.fromJson(
            data as Map<String, dynamic>,
          ),
        );
        return apiResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Нет доступа',
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка сервера: ${response.statusCode}',
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
