import 'package:flutter/foundation.dart';

/// Провайдер для управления навигацией в desktop версии
/// 
/// Отвечает за:
/// - Текущий блок (operational/financial/admin/analytics)
/// - Текущий маршрут внутри блока
/// - Состояние левой навигационной панели (свернута/развернута)
class DesktopNavigationProvider extends ChangeNotifier {
  // Текущий выбранный блок
  String _currentBlock = 'operational';
  
  // Текущий маршрут внутри блока
  String? _currentRoute;
  
  // Состояние левой панели (свернута или нет)
  bool _isLeftPanelCollapsed = false;

  /// Получить текущий блок
  String get currentBlock => _currentBlock;

  /// Получить текущий маршрут
  String? get currentRoute => _currentRoute;

  /// Проверить, свернута ли левая панель
  bool get isLeftPanelCollapsed => _isLeftPanelCollapsed;

  /// Установить текущий блок
  /// При смене блока текущий маршрут сбрасывается
  void setBlock(String block) {
    if (_currentBlock != block) {
      _currentBlock = block;
      _currentRoute = null; // Сбрасываем маршрут при смене блока
      debugPrint('🔄 Desktop Navigation: Changed block to $_currentBlock');
      notifyListeners();
    }
  }

  /// Навигация к конкретному маршруту
  void navigateTo(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      debugPrint('🔄 Desktop Navigation: Navigated to $_currentRoute');
      notifyListeners();
    }
  }

  /// Переключить состояние левой панели (свернуть/развернуть)
  void toggleLeftPanel() {
    _isLeftPanelCollapsed = !_isLeftPanelCollapsed;
    debugPrint(
      '🔄 Desktop Navigation: Left panel ${_isLeftPanelCollapsed ? "collapsed" : "expanded"}',
    );
    notifyListeners();
  }

  /// Сбросить навигацию к дефолтному состоянию
  void reset() {
    _currentBlock = 'operational';
    _currentRoute = null;
    _isLeftPanelCollapsed = false;
    debugPrint('🔄 Desktop Navigation: Reset to default state');
    notifyListeners();
  }

  /// Получить дефолтный маршрут для текущего блока
  String? getDefaultRouteForBlock(String block) {
    switch (block) {
      case 'operational':
        return '/business/operational';
      case 'financial':
        return '/business/financial';
      case 'admin':
        return '/business/admin';
      case 'analytics':
        return '/business/analytics';
      default:
        return null;
    }
  }

  /// Проверить, является ли данный маршрут активным
  bool isRouteActive(String route) {
    return _currentRoute == route;
  }
}
