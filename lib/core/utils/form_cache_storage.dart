import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для кэширования данных форм
class FormCacheStorage {
  static FormCacheStorage? _instance;
  static const String _keyPrefix = 'form_cache_';

  FormCacheStorage._();

  static FormCacheStorage get instance {
    _instance ??= FormCacheStorage._();
    return _instance!;
  }

  /// Сохранить данные формы
  Future<void> saveFormData(String key, Map<String, dynamic> formData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(formData);
      await prefs.setString('$_keyPrefix$key', jsonString);
    } catch (e) {
      // Игнорируем ошибки сохранения, чтобы не ломать работу приложения
      print('Ошибка сохранения формы в кэш: $e');
    }
  }

  /// Загрузить данные формы
  Future<Map<String, dynamic>?> loadFormData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_keyPrefix$key');
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      // Если не удалось загрузить, возвращаем null
      print('Ошибка загрузки формы из кэша: $e');
      return null;
    }
  }

  /// Очистить данные формы
  Future<void> clearFormData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyPrefix$key');
    } catch (e) {
      print('Ошибка очистки формы из кэша: $e');
    }
  }

  /// Проверить наличие данных формы
  Future<bool> hasFormData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_keyPrefix$key');
    } catch (e) {
      return false;
    }
  }
}
