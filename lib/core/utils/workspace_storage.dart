import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище для сохранения выбранного workspace
class WorkspaceStorage {
  static const String _keySelectedWorkspaceId = 'selected_workspace_id';

  /// Сохранить ID выбранного workspace
  static Future<void> saveSelectedWorkspaceId(String workspaceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedWorkspaceId, workspaceId);
  }

  /// Получить сохраненный ID workspace
  static Future<String?> getSelectedWorkspaceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedWorkspaceId);
  }

  /// Очистить сохраненный workspace
  static Future<void> clearSelectedWorkspaceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySelectedWorkspaceId);
  }

  /// Проверить, есть ли сохраненный workspace
  static Future<bool> hasSelectedWorkspace() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keySelectedWorkspaceId);
  }
}


