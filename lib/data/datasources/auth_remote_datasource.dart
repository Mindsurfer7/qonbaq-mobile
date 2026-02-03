import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../models/register_request.dart';
import '../models/login_request.dart';
import '../models/guest_login_request.dart';
import '../models/auth_response.dart';
import '../models/api_response.dart';
import '../datasources/datasource.dart';

/// Удаленный источник данных для аутентификации
class AuthRemoteDataSource extends DataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Регистрация пользователя
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.post(
        '/auth/register',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final details = json['details'] as List<dynamic>?;
        final message =
            details?.isNotEmpty == true
                ? details!.first.toString()
                : 'Ошибка валидации';
        throw Exception(message);
      } else if (response.statusCode == 409) {
        throw Exception(
          'Пользователь с таким email уже существует',
        );
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

  /// Вход пользователя
  Future<AuthResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final details = json['details'] as List<dynamic>?;
        final message =
            details?.isNotEmpty == true
                ? details!.first.toString()
                : 'Ошибка валидации';
        throw Exception(message);
      } else if (response.statusCode == 401) {
        throw Exception('Неверный email или пароль');
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

  /// Обновление токена через refresh token
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await apiClient.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Refresh токен недействителен');
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

  /// Гостевой вход
  Future<AuthResponse> guestLogin(GuestLoginRequest request) async {
    try {
      final response = await apiClient.post(
        '/guest/login',
        body: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => AuthResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = json['error'] as String?;
        final message = json['message'] as String?;
        throw Exception(message ?? error ?? 'Неверный формат UUID');
      } else if (response.statusCode == 403) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = json['error'] as String?;
        final message = json['message'] as String?;
        throw Exception(
          message ?? error ?? 'Нет доступа к этому бизнесу',
        );
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        final error = json?['error'] as String?;
        final message = json?['message'] as String?;
        throw Exception(
          message ?? error ?? 'Ошибка создания гостевой сессии',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }
}
