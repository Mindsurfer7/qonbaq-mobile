import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для сохранения учетных данных пользователя
class CredentialsStorage {
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';

  /// Сохранить email и пароль
  static Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
  }

  /// Получить сохраненный email
  static Future<String?> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail);
  }

  /// Получить сохраненный пароль
  static Future<String?> getSavedPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword);
  }

  /// Получить сохраненные учетные данные
  static Future<Map<String, String?>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyEmail),
      'password': prefs.getString(_keyPassword),
    };
  }

  /// Очистить сохраненные учетные данные
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
  }

  /// Проверить, есть ли сохраненные учетные данные
  static Future<bool> hasSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyEmail) && prefs.containsKey(_keyPassword);
  }
}



