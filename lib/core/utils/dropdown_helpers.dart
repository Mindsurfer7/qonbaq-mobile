import 'package:flutter/material.dart';
import '../theme/theme_extensions.dart';

/// Создает стилизованный DropdownMenuItem с бордером и отступами из темы
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
    child: Container(
      margin: EdgeInsets.symmetric(
        horizontal: theme.dropdownItemGap,
        vertical: theme.dropdownItemGap / 2,
      ),
      padding: theme.dropdownItemPaddingInsets,
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.borderPrimary,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(theme.borderRadius),
        color: theme.backgroundSurface,
      ),
      child: child,
    ),
  );
}

