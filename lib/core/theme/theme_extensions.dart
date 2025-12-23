import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qonbaq/presentation/providers/theme_provider.dart';
import 'app_theme.dart';

/// Extension для удобного доступа к теме через BuildContext
extension ThemeExtension on BuildContext {
  /// Получить текущую тему приложения
  AppTheme get appTheme {
    final themeProvider = Provider.of<ThemeProvider>(this, listen: false);
    return themeProvider.currentTheme;
  }

  /// Получить ThemeProvider
  ThemeProvider get themeProvider {
    return Provider.of<ThemeProvider>(this);
  }
}

