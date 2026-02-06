import 'package:flutter/foundation.dart';

/// Провайдер для отслеживания текущего блока на desktop
/// 
/// Используется для визуального состояния панелей
/// Навигация теперь управляется через go_router
class DesktopNavigationProvider extends ChangeNotifier {
  // Текущий выбранный блок
  String _currentBlock = 'operational';
  
  // Состояние левой панели (свернута или нет)
  bool _isLeftPanelCollapsed = false;

  /// Получить текущий блок
  String get currentBlock => _currentBlock;

  /// Проверить, свернута ли левая панель
  bool get isLeftPanelCollapsed => _isLeftPanelCollapsed;

  /// Установить блок на основе route (вызывается из router)
  void setBlockFromRoute(String route) {
    String newBlock = 'operational';
    
    if (route.startsWith('/business/financial')) {
      newBlock = 'financial';
    } else if (route.startsWith('/business/admin')) {
      newBlock = 'admin';
    } else if (route.startsWith('/business/analytics')) {
      newBlock = 'analytics';
    } else if (route.startsWith('/business/operational')) {
      newBlock = 'operational';
    }
    
    if (_currentBlock != newBlock) {
      _currentBlock = newBlock;
      debugPrint('🔄 Desktop Navigation: Block changed to $_currentBlock (from route: $route)');
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
    _isLeftPanelCollapsed = false;
    debugPrint('🔄 Desktop Navigation: Reset to default state');
    notifyListeners();
  }
}
