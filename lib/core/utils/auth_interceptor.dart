import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_response.dart';
import '../../presentation/providers/pending_confirmations_provider.dart';
import '../../presentation/providers/profile_provider.dart';

/// Интерсептор для автоматической обработки 401 ошибок и обновления токенов
class AuthInterceptor {
  final AuthRemoteDataSource authDataSource;
  final GlobalKey<NavigatorState>? navigatorKey;
  bool _isRefreshing = false;
  Future<AuthResponse?>? _refreshFuture;

  AuthInterceptor({
    required this.authDataSource,
    this.navigatorKey,
  });

  /// Обработка ответа с автоматическим обновлением токена при 401
  /// Возвращает true, если токен был обновлен и запрос нужно повторить
  Future<bool> interceptResponse(http.Response response) async {
    // Если не 401, ничего не делаем
    if (response.statusCode != 401) {
      return false;
    }

    // Если это запрос на обновление токена или логин, не обрабатываем
    final uri = response.request?.url.toString() ?? '';
    if (uri.contains('/auth/refresh') || uri.contains('/auth/login') || uri.contains('/auth/register')) {
      // Если это refresh и он вернул 401, значит refresh токен недействителен
      if (uri.contains('/auth/refresh')) {
        _redirectToLogin();
      }
      return false;
    }

    // Пытаемся обновить токен
    final refreshToken = TokenStorage.instance.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // Нет refresh токена - перенаправляем на логин
      _redirectToLogin();
      return false;
    }

    // Обновляем токен
    try {
      final newTokens = await _refreshToken(refreshToken);
      if (newTokens == null) {
        // Не удалось обновить - перенаправляем на логин
        _redirectToLogin();
        return false;
      }

      // Токен обновлен, нужно повторить запрос
      return true;
    } catch (e) {
      // Ошибка при обновлении токена - перенаправляем на логин
      _redirectToLogin();
      return false;
    }
  }

  /// Обновление токена (с защитой от параллельных запросов)
  Future<AuthResponse?> _refreshToken(String refreshToken) async {
    // Если уже идет обновление, ждем его
    if (_isRefreshing && _refreshFuture != null) {
      return await _refreshFuture;
    }

    _isRefreshing = true;
    _refreshFuture = _doRefreshToken(refreshToken);

    try {
      final result = await _refreshFuture;
      return result;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }

  /// Выполнение обновления токена
  Future<AuthResponse?> _doRefreshToken(String refreshToken) async {
    try {
      final response = await authDataSource.refreshToken(refreshToken);
      // Токены уже сохранены в TokenStorage через AuthRepository
      return response;
    } catch (e) {
      // Очищаем токены при ошибке
      await TokenStorage.instance.clearTokens();
      return null;
    }
  }

  /// Перенаправление на страницу логина
  void _redirectToLogin() {
    // Очищаем токены
    TokenStorage.instance.clearTokens();
    
    // Очищаем провайдеры перед перенаправлением
    if (navigatorKey?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey?.currentContext;
        if (context != null) {
          try {
            // Очищаем провайдеры, если они доступны
            final pendingProvider = Provider.of<PendingConfirmationsProvider>(
              context,
              listen: false,
            );
            final profileProvider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            
            pendingProvider.clear();
            profileProvider.clear();
          } catch (e) {
            // Игнорируем ошибки, если провайдеры недоступны
            // (например, если контекст еще не инициализирован)
          }
          
          // Перенаправляем на страницу логина
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        }
      });
    }
  }
}

