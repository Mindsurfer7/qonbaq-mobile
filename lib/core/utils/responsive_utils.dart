import 'package:flutter/material.dart';

/// Утилиты для определения типа устройства и адаптивной верстки
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Проверяет, является ли устройство мобильным (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Проверяет, является ли устройство планшетом (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Проверяет, является ли устройство десктопом (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Возвращает ширину экрана
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Возвращает высоту экрана
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Возвращает тип устройства как enum
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }
}

/// Enum для типов устройств
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Extension для удобного доступа к responsive методам через context
extension ResponsiveContext on BuildContext {
  /// Является ли устройство мобильным
  bool get isMobile => ResponsiveUtils.isMobile(this);

  /// Является ли устройство планшетом
  bool get isTablet => ResponsiveUtils.isTablet(this);

  /// Является ли устройство десктопом
  bool get isDesktop => ResponsiveUtils.isDesktop(this);

  /// Ширина экрана
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);

  /// Высота экрана
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  /// Тип устройства
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
}
