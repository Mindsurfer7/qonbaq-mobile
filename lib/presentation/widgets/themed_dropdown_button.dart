import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

/// Кастомный DropdownButtonFormField со стилизацией элементов списка
/// Использует параметры из темы приложения для скруглений, отступов и бордеров
class ThemedDropdownButtonFormField<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;
  final InputDecoration? decoration;
      final DropdownButtonBuilder? selectedItemBuilder;

  const ThemedDropdownButtonFormField({
    super.key,
    required this.items,
    this.value,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.validator,
    this.isExpanded = false,
    this.decoration,
    this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: isExpanded,
      selectedItemBuilder: selectedItemBuilder,
      decoration: decoration ??
          InputDecoration(
            labelText: labelText,
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              borderSide: BorderSide(color: theme.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              borderSide: BorderSide(color: theme.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              borderSide: BorderSide(color: theme.borderActive, width: 2),
            ),
          ),
      // Стилизация элементов через dropdownColor (фон списка)
      dropdownColor: theme.backgroundSurface,
      // Кастомизация элементов через меню стиль
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(theme.borderRadius),
      // Стилизация каждого элемента
      itemHeight: null, // Используем дефолтную высоту
      style: TextStyle(
        color: theme.textPrimary,
        fontSize: 16,
      ),
    );
  }
}

/// Вспомогательная функция для создания стилизованного DropdownMenuItem
/// Оборачивает child в Container с бордером и отступами из темы
/// 
/// Пример использования:
/// ```dart
/// items: options.map((option) => createThemedDropdownMenuItem<String>(
///   context: context,
///   value: option,
///   child: Text(option),
/// )).toList(),
/// ```
DropdownMenuItem<T> createThemedDropdownMenuItem<T>({
  required T value,
  required BuildContext context,
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

