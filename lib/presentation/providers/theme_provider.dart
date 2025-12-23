import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_theme_light.dart';
import '../../core/theme/app_theme_dark.dart';

/// Провайдер для управления темой приложения
/// Позволяет переключаться между светлой и темной темой
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  AppTheme _currentTheme = AppThemeLight();
  bool _isDarkMode = false;

  ThemeProvider() {
    _loadTheme();
  }

  /// Текущая тема
  AppTheme get currentTheme => _currentTheme;

  /// Флаг темной темы
  bool get isDarkMode => _isDarkMode;

  /// Переключение темы
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    _currentTheme = _isDarkMode ? AppThemeDark() : AppThemeLight();
    await _saveTheme();
    notifyListeners();
  }

  /// Установка светлой темы
  Future<void> setLightTheme() async {
    if (_isDarkMode) {
      _isDarkMode = false;
      _currentTheme = AppThemeLight();
      await _saveTheme();
      notifyListeners();
    }
  }

  /// Установка темной темы
  Future<void> setDarkTheme() async {
    if (!_isDarkMode) {
      _isDarkMode = true;
      _currentTheme = AppThemeDark();
      await _saveTheme();
      notifyListeners();
    }
  }

  /// Загрузка сохраненной темы
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _isDarkMode = isDark;
      _currentTheme = _isDarkMode ? AppThemeDark() : AppThemeLight();
      notifyListeners();
    } catch (e) {
      // В случае ошибки используем светлую тему по умолчанию
      _isDarkMode = false;
      _currentTheme = AppThemeLight();
    }
  }

  /// Сохранение текущей темы
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      // Игнорируем ошибки сохранения
      debugPrint('Ошибка сохранения темы: $e');
    }
  }
}

