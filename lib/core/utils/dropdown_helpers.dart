import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// Создает стилизованный DropdownMenuItem с бордером и отступами из темы
/// При ховере меняет цвет фона на более темный и бордер на черный
/// 
/// Использование:
/// ```dart
/// items: options.map((option) => createStyledDropdownItem<String>(
///   context: context,
///   value: option,
///   child: Text(option),
/// )).toList(),
/// ```
DropdownMenuItem<T> createStyledDropdownItem<T>({
  required BuildContext context,
  required T value,
  required Widget child,
  bool enabled = true,
}) {
  final theme = context.appTheme;

  return DropdownMenuItem<T>(
    value: value,
    enabled: enabled,
    // Используем Material для отключения стандартного hover эффекта
    child: Material(
      color: Colors.transparent,
      child: _HoverableDropdownItem(
        theme: theme,
        child: child,
      ),
    ),
  );
}

/// Внутренний виджет для обработки ховера и стилизации элемента дроп-дауна
class _HoverableDropdownItem extends StatefulWidget {
  final dynamic theme;
  final Widget child;

  const _HoverableDropdownItem({
    required this.theme,
    required this.child,
  });

  @override
  State<_HoverableDropdownItem> createState() => _HoverableDropdownItemState();
}

class _HoverableDropdownItemState extends State<_HoverableDropdownItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    
    // Более темный серый для ховера (примерно 15% темнее для светлой темы)
    Color hoverBackgroundColor;
    if (theme.brightness == Brightness.light) {
      // Для светлой темы делаем фон темнее
      hoverBackgroundColor = Color.lerp(theme.backgroundSurface, Colors.black, 0.15) ?? theme.backgroundSurface;
    } else {
      // Для темной темы делаем фон светлее
      hoverBackgroundColor = Color.lerp(theme.backgroundSurface, Colors.white, 0.15) ?? theme.backgroundSurface;
    }
    
    final borderColor = _isHovered 
        ? Colors.black 
        : theme.borderPrimary;

    return InkWell(
      // Отключаем стандартный splash и highlight эффекты
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: null, // Отключаем обработку tap, так как DropdownMenuItem сам обрабатывает
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: double.infinity, // 100% ширины родителя
          margin: EdgeInsets.symmetric(
            horizontal: theme.dropdownItemGap,
            vertical: theme.dropdownItemGap / 2,
          ),
          padding: theme.dropdownItemPaddingInsets,
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(theme.borderRadius),
            color: _isHovered ? hoverBackgroundColor : theme.backgroundSurface,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

