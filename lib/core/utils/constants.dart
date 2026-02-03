import 'package:flutter/foundation.dart' show kIsWeb;

/// Общие константы приложения
class AppConstants {
  AppConstants._();

  // Название приложения
  static const String appName = 'Qonbaq';

  // Версия API (если нужно)
  static const String apiVersion = 'v1';

  // Базовый URL API (вшивается в билд через --dart-define)
  static String get apiBaseUrl {
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }
    // Дефолтное значение для разработки (если не задано через --dart-define)
    return 'http://localhost:3000';
  }

  // Базовый URL фронтенда (для формирования ссылок инвайтов)
  static String get frontendBaseUrl {
    if (kIsWeb) {
      // На веб - используем текущий origin
      try {
        final uri = Uri.base;
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      } catch (e) {
        // Fallback на дефолт для веба
        return 'http://localhost:1111';
      }
    } else {
      // На мобильных - из --dart-define или дефолт
      const dartDefineUrl = String.fromEnvironment('FRONTEND_BASE_URL');
      if (dartDefineUrl.isNotEmpty) {
        return dartDefineUrl;
      }
      return 'https://qonbaq.com';
    }
  }

  /// Сформировать ссылку для инвайта
  static String buildInviteLink(String inviteCode) {
    return '$frontendBaseUrl/register?invite=$inviteCode';
  }
}
