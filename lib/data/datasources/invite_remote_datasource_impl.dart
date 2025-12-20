import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/invite_remote_datasource.dart';
import '../models/invite_model.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для приглашений
class InviteRemoteDataSourceImpl extends InviteRemoteDataSource {
  final ApiClient apiClient;

  InviteRemoteDataSourceImpl({required this.apiClient});

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
  Future<CreateInviteResultModel> createInvite({
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (maxUses != null) {
        body['maxUses'] = maxUses;
      }
      if (expiresAt != null) {
        body['expiresAt'] = expiresAt.toIso8601String();
      }

      // Отправляем пустой объект {} вместо null, чтобы избежать ошибки
      // "Body cannot be empty when content-type is set to 'application/json'"
      final response = await apiClient.post(
        '/api/invites',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CreateInviteResultModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final message = json['error'] as String? ?? 'Ошибка валидации';
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
  Future<CreateInviteResultModel?> getCurrentInvite() async {
    try {
      final response = await apiClient.get(
        '/api/invites/current',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => CreateInviteResultModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 404) {
        // Активного инвайта нет - это нормальная ситуация
        return null;
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

