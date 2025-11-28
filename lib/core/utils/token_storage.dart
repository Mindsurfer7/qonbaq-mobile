import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище токенов авторизации с сохранением в SharedPreferences
class TokenStorage {
  static TokenStorage? _instance;
  String? _accessToken;
  String? _refreshToken;
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  TokenStorage._();

  static TokenStorage get instance {
    _instance ??= TokenStorage._();
    return _instance!;
  }

  /// Инициализация - загрузка токенов из SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);
  }

  /// Сохранить access токен
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
  }

  /// Сохранить refresh токен
  Future<void> setRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRefreshToken, token);
  }

  /// Сохранить оба токена
  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  /// Получить access токен
  String? getAccessToken() {
    return _accessToken;
  }

  /// Получить refresh токен
  String? getRefreshToken() {
    return _refreshToken;
  }

  /// Очистить токены
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }

  /// Проверить наличие access токена
  bool hasAccessToken() {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  /// Проверить наличие refresh токена
  bool hasRefreshToken() {
    return _refreshToken != null && _refreshToken!.isNotEmpty;
  }

  /// Проверить наличие токенов
  bool hasTokens() {
    return hasAccessToken() && hasRefreshToken();
  }
}


