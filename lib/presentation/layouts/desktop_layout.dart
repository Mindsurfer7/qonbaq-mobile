import 'package:flutter/material.dart';
import '../widgets/desktop/desktop_top_bar.dart';
import '../widgets/desktop/desktop_left_nav_panel.dart';
import '../widgets/desktop/desktop_right_blocks_panel.dart';
import '../widgets/desktop/desktop_bottom_bar.dart';
import '../widgets/desktop/desktop_navigator.dart';

/// Desktop layout с трехпанельной структурой
/// 
/// Структура:
/// ```
/// ┌─────────────────────────────────────────────────────────┐
/// │                    Desktop Top Bar                       │
/// ├──────────────┬─────────────────────────┬────────────────┤
/// │              │                         │                │
/// │   Left Nav   │    Content Area         │  Right Blocks  │
/// │   Panel      │    (Desktop Navigator)  │  Panel         │
/// │              │                         │                │
/// │              │                         │                │
/// └──────────────┴─────────────────────────┴────────────────┘
/// │                  Desktop Bottom Bar                      │
/// └─────────────────────────────────────────────────────────┘
/// ```
class DesktopLayout extends StatelessWidget {
  const DesktopLayout({super.key});

  @override
  Widget build(BuildContext context) {
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
                const DesktopLeftNavPanel(),
                
                // Центральная область контента
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background,
                    child: const DesktopNavigator(),
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
