import 'package:flutter/material.dart';
import '../widgets/desktop/desktop_top_bar.dart';
import '../widgets/desktop/desktop_left_nav_panel.dart';
import '../widgets/desktop/desktop_right_blocks_panel.dart';
import '../widgets/desktop/desktop_bottom_bar.dart';

/// Desktop layout с трехпанельной структурой
/// 
/// Структура:
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │                    Desktop Top Bar                       │
/// ├──────────────┬─────────────────────────┬────────────────┤
/// │              │                         │                │
/// │   Left Nav   │    Content Area         │  Right Blocks  │
/// │   Panel      │    (go_router child)    │  Panel         │
/// │              │                         │                │
/// │              │                         │                │
/// └──────────────┴─────────────────────────┴────────────────┘
/// │                  Desktop Bottom Bar                      │
/// └─────────────────────────────────────────────────────────┘
/// ```
class DesktopLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  
  const DesktopLayout({
    super.key, 
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ [DesktopLayout] build вызван для route: $currentRoute');
    debugPrint('   🔑 Key виджета child: ${ValueKey(currentRoute)}');
    return Scaffold(
      body: Column(
        children: [
          // Верхняя панель
          const DesktopTopBar(),
          
          // Основной контент с тремя панелями
          Expanded(
            child: Row(
              children: [
                // Левая навигационная панель
                DesktopLeftNavPanel(currentRoute: currentRoute),
                
                // Центральная область контента
                Expanded(
                  child: Container(
                    key: ValueKey(currentRoute),
                    color: Theme.of(context).colorScheme.surface,
                    child: child, // ← go_router рендерит страницы здесь
                  ),
                ),
                
                // Правая панель с блоками
                const DesktopRightBlocksPanel(),
              ],
            ),
          ),
          
          // Нижняя панель
          const DesktopBottomBar(),
        ],
      ),
    );
  }
}
