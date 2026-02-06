import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'desktop_layout.dart';

/// Адаптивная оболочка, которая переключает между mobile и desktop layouts
/// 
/// На mobile (< 1024px): возвращает child без изменений
/// На desktop (>= 1024px): показывает DesktopLayout с тремя панелями
/// 
/// Это позволяет одному и тому же коду работать на обеих платформах
/// без изменения существующих страниц.
class AdaptiveShell extends StatelessWidget {
  final Widget child;

  const AdaptiveShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Проверяем размер экрана
    final isDesktop = context.isDesktop;
    
    if (!isDesktop) {
      // Mobile - возвращаем child как есть
      return child;
    }
    
    // Desktop - показываем DesktopLayout
    // child игнорируется, используется DesktopNavigator внутри
    return const DesktopLayout();
  }
}
