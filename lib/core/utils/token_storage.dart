/// Простое хранилище токена авторизации
class TokenStorage {
  static TokenStorage? _instance;
  String? _accessToken;

  TokenStorage._();

  static TokenStorage get instance {
    _instance ??= TokenStorage._();
    return _instance!;
  }

  /// Сохранить токен
  void setAccessToken(String token) {
    _accessToken = token;
  }

  /// Получить токен
  String? getAccessToken() {
    return _accessToken;
  }

  /// Очистить токен
  void clearToken() {
    _accessToken = null;
  }

  /// Проверить наличие токена
  bool hasToken() {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }
}


