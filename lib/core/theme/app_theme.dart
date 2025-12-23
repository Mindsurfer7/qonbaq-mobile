import 'package:flutter/material.dart';

/// Базовый класс для определения темы приложения
/// Содержит все стилевые параметры: цвета, скругления, размеры и т.д.
abstract class AppTheme {
  // Цвета фона
  Color get backgroundPrimary;
  Color get backgroundSecondary;
  Color get backgroundActive;
  Color get backgroundSurface; // Для карточек и поверхностей

  // Цвета текста
  Color get textPrimary;
  Color get textSecondary;
  Color get textMuted;
  Color get textInverse; // Текст на темном фоне

  // Акцентные цвета
  Color get accentPrimary; // Основной акцент (желтый)
  Color get accentSecondary;
  Color get accentHover;

  // Статусные цвета
  Color get statusSuccess;
  Color get statusError;
  Color get statusWarning;
  Color get statusInfo;

  // Цвета границ
  Color get borderPrimary;
  Color get borderSecondary;
  Color get borderActive;

  // Цвета навигации
  Color get navigationBackground;
  Color get navigationActive;
  Color get navigationInactive;

  // Цвета сайдбара
  Color get sidebarBackground;
  Color get sidebarActive;
  Color get sidebarHover;

  // Цвета для графиков и визуализации
  Color get chartPrimary;
  Color get chartSecondary;
  Color get chartGrid;

  // Скругления
  double get borderRadius;

  // Параметры для дроп-даунов и меню
  double get dropdownItemPadding;
  double get dropdownItemGap;
  EdgeInsets get dropdownItemPaddingInsets;

  // Создает ThemeData для MaterialApp
  ThemeData get themeData;

  // Brightness темы
  Brightness get brightness;
}

