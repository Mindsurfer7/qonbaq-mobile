import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/responsive_utils.dart';
import '../providers/desktop_navigation_provider.dart';
import '../widgets/mobile/mobile_top_panel.dart';
import '../widgets/mobile/mobile_bottom_panel.dart';
import 'desktop_layout.dart';

/// Адаптивная оболочка приложения со статичными панелями
/// 
/// Desktop: 3-панельный layout (left, center, right) + top/bottom bars
/// Mobile: center + top/bottom panels
/// 
/// child - это страница которую рендерит go_router
class AdaptiveAppShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  
  const AdaptiveAppShell({
    super.key, 
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AdaptiveAppShell> createState() => _AdaptiveAppShellState();
}

class _AdaptiveAppShellState extends State<AdaptiveAppShell> {
  @override
  void didUpdateWidget(AdaptiveAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем navigation provider когда route меняется
    // ВАЖНО: используем addPostFrameCallback чтобы не вызвать notifyListeners во время build
    if (oldWidget.currentRoute != widget.currentRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateNavigationProvider();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Обновляем при первой загрузке
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateNavigationProvider();
      }
    });
  }

  void _updateNavigationProvider() {
    if (!mounted) return;
    try {
      final navProvider = Provider.of<DesktopNavigationProvider>(
        context,
        listen: false,
      );
      navProvider.setBlockFromRoute(widget.currentRoute);
    } catch (e) {
      // Игнорируем ошибки если context уже недоступен
      debugPrint('⚠️ AdaptiveAppShell: Could not update nav provider: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _buildDesktopShell(context);
    } else {
      return _buildMobileShell(context);
    }
  }
  
  Widget _buildDesktopShell(BuildContext context) {
    return DesktopLayout(
      child: widget.child,
      currentRoute: widget.currentRoute,
    );
  }
  
  Widget _buildMobileShell(BuildContext context) {
    // Не оборачиваем в Scaffold - страницы сами имеют свой Scaffold
    // Добавляем только top и bottom панели
    return Column(
      children: [
        // Top panel безопасно вне Scaffold
        Material(
          child: SafeArea(
            bottom: false,
            child: const MobileTopPanel(),
          ),
        ),
        // Основной контент (страница со своим Scaffold)
        Expanded(
          child: widget.child,
        ),
        // Bottom panel
        Material(
          child: SafeArea(
            top: false,
            child: const MobileBottomPanel(),
          ),
        ),
      ],
    );
  }
}
