import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для отслеживания показов поп-апа о неназначенных ролях
class UnassignedRolesPopupStorage {
  static const String _keyShowCount = 'unassigned_roles_popup_show_count';
  static const String _keyShouldHide = 'unassigned_roles_popup_should_hide';
  static const int _maxShowCount = 3;

  /// Получить текущий счетчик показов
  static Future<int> getShowCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyShowCount) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Проверить, нужно ли скрывать поп-ап
  static Future<bool> shouldHidePopup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyShouldHide) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Увеличить счетчик показов и проверить, нужно ли скрыть поп-ап
  /// Возвращает true, если поп-ап нужно показать, false - если скрыть
  static Future<bool> incrementShowCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Проверяем, не установлен ли уже флаг скрытия
      final shouldHide = prefs.getBool(_keyShouldHide) ?? false;
      if (shouldHide) {
        return false;
      }

      // Увеличиваем счетчик
      final currentCount = prefs.getInt(_keyShowCount) ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt(_keyShowCount, newCount);

      // Если достигли максимума, устанавливаем флаг скрытия
      if (newCount >= _maxShowCount) {
        await prefs.setBool(_keyShouldHide, true);
        return false;
      }

      return true;
    } catch (e) {
      // В случае ошибки показываем поп-ап
      return true;
    }
  }

  /// Сбросить счетчик и флаг (для тестирования или сброса настроек)
  static Future<void> reset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyShowCount);
      await prefs.remove(_keyShouldHide);
    } catch (e) {
      // Игнорируем ошибки
    }
  }
}
