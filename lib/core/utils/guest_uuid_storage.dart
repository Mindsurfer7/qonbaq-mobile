import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для сохранения guest UUID
class GuestUuidStorage {
  static const String _keyGuestUuid = 'guest_uuid';

  /// Сохранить guest UUID
  static Future<void> saveGuestUuid(String guestUuid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGuestUuid, guestUuid);
  }

  /// Получить сохраненный guest UUID
  static Future<String?> getGuestUuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyGuestUuid);
  }

  /// Очистить сохраненный guest UUID
  static Future<void> clearGuestUuid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGuestUuid);
  }

  /// Проверить, есть ли сохраненный guest UUID
  static Future<bool> hasGuestUuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyGuestUuid);
  }
}
