import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Светлая тема приложения
class AppThemeLight extends AppTheme {
  // Основные цвета из дизайна
  static const Color _yellowAccent = Color(0xFFF0D400);
  static const Color _lightGrayBackground = Color(0xFFF5F5F5);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1A1A);
  static const Color _textMedium = Color(0xFF666666);
  static const Color _textLight = Color(0xFF999999);

  @override
  Color get backgroundPrimary => _lightGrayBackground;

  @override
  Color get backgroundSecondary => _white;

  @override
  Color get backgroundActive => _yellowAccent.withValues(alpha: 0.1);

  @override
  Color get backgroundSurface => _white;

  @override
  Color get textPrimary => _textDark;

  @override
  Color get textSecondary => _textMedium;

  @override
  Color get textMuted => _textLight;

  @override
  Color get textInverse => _white;

  @override
  Color get accentPrimary => _yellowAccent;

  @override
  Color get accentSecondary => _yellowAccent.withValues(alpha: 0.8);

  @override
  Color get accentHover => const Color(0xFFE6C500);

  @override
  Color get statusSuccess => const Color(0xFF4CAF50);

  @override
  Color get statusError => const Color(0xFFF44336);

  @override
  Color get statusWarning => const Color(0xFFFF9800);

  @override
  Color get statusInfo => const Color(0xFF2196F3);

  @override
  Color get borderPrimary => const Color(0xFFE0E0E0);

  @override
  Color get borderSecondary => const Color(0xFFF0F0F0);

  @override
  Color get borderActive => _yellowAccent;

  @override
  Color get navigationBackground => _white;

  @override
  Color get navigationActive => _yellowAccent;

  @override
  Color get navigationInactive => _textMedium;

  @override
  Color get sidebarBackground => _white;

  @override
  Color get sidebarActive => _yellowAccent.withValues(alpha: 0.1);

  @override
  Color get sidebarHover => const Color(0xFFF5F5F5);

  @override
  Color get chartPrimary => _yellowAccent;

  @override
  Color get chartSecondary => const Color(0xFF9E9E9E);

  @override
  Color get chartGrid => const Color(0xFFE0E0E0);

  @override
  double get borderRadius => 12.0;

  @override
  double get dropdownItemPadding => 12.0;

  @override
  double get dropdownItemGap => 4.0;

  @override
  EdgeInsets get dropdownItemPaddingInsets =>
      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0);

  @override
  Brightness get brightness => Brightness.light;

  @override
  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.light(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: backgroundSurface,
        error: statusError,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textInverse,
      ),
      scaffoldBackgroundColor: backgroundPrimary,
      cardColor: backgroundSurface,
      cardTheme: CardTheme(
        color: backgroundSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundSecondary,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: borderActive, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentPrimary,
          side: BorderSide(color: borderActive),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: borderPrimary,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 24),
      // Стилизация выпадающих меню (DropdownMenu, MenuButton)
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(backgroundSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(color: borderPrimary, width: 1),
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(vertical: dropdownItemGap),
          ),
        ),
      ),
      // Стилизация PopupMenu
      popupMenuTheme: PopupMenuThemeData(
        color: backgroundSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: borderPrimary, width: 1),
        ),
        elevation: 4,
      ),
      // Стилизация MenuButton (Material 3)
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(backgroundSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(color: borderPrimary, width: 1),
            ),
          ),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(vertical: dropdownItemGap),
          ),
        ),
      ),
    );
  }
}
