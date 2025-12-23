import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Темная тема приложения
class AppThemeDark extends AppTheme {
  // Основные цвета для темной темы
  static const Color _yellowAccent = Color(0xFFF0D400);
  static const Color _darkBackground = Color(0xFF262E3B);
  static const Color _darkSurface = Color(0xFF2F3A4A);
  static const Color _darkerSurface = Color(0xFF1F2733);
  static const Color _textLight = Color(0xFFFFFFFF);
  static const Color _textMedium = Color(0xFFB0B0B0);
  static const Color _textDark = Color(0xFF8A8A8A);

  @override
  Color get backgroundPrimary => _darkBackground;

  @override
  Color get backgroundSecondary => _darkSurface;

  @override
  Color get backgroundActive => _yellowAccent.withValues(alpha: 0.15);

  @override
  Color get backgroundSurface => _darkSurface;

  @override
  Color get textPrimary => _textLight;

  @override
  Color get textSecondary => _textMedium;

  @override
  Color get textMuted => _textDark;

  @override
  Color get textInverse => _darkBackground;

  @override
  Color get accentPrimary => _yellowAccent;

  @override
  Color get accentSecondary => _yellowAccent.withValues(alpha: 0.8);

  @override
  Color get accentHover => const Color(0xFFE6C500);

  @override
  Color get statusSuccess => const Color(0xFF66BB6A);

  @override
  Color get statusError => const Color(0xFFEF5350);

  @override
  Color get statusWarning => const Color(0xFFFFA726);

  @override
  Color get statusInfo => const Color(0xFF42A5F5);

  @override
  Color get borderPrimary => const Color(0xFF3A4555);

  @override
  Color get borderSecondary => const Color(0xFF2F3A4A);

  @override
  Color get borderActive => _yellowAccent;

  @override
  Color get navigationBackground => _darkerSurface;

  @override
  Color get navigationActive => _yellowAccent;

  @override
  Color get navigationInactive => _textMedium;

  @override
  Color get sidebarBackground => _darkerSurface;

  @override
  Color get sidebarActive => _yellowAccent.withValues(alpha: 0.15);

  @override
  Color get sidebarHover => const Color(0xFF374151);

  @override
  Color get chartPrimary => _yellowAccent;

  @override
  Color get chartSecondary => const Color(0xFF9E9E9E);

  @override
  Color get chartGrid => const Color(0xFF3A4555);

  @override
  double get borderRadius => 12.0;

  @override
  double get dropdownItemPadding => 12.0;

  @override
  double get dropdownItemGap => 4.0;

  @override
  EdgeInsets get dropdownItemPaddingInsets => const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 8.0,
      );

  @override
  Brightness get brightness => Brightness.dark;

  @override
  ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: backgroundSurface,
        error: statusError,
        onPrimary: textInverse,
        onSecondary: textInverse,
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
          foregroundColor: textInverse,
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
      iconTheme: IconThemeData(
        color: textPrimary,
        size: 24,
      ),
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

