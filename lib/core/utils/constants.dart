import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Общие константы приложения
class AppConstants {
  AppConstants._();

  // Название приложения
  static const String appName = 'Qonbaq';

  // Версия API (если нужно)
  static const String apiVersion = 'v1';

  // Базовый URL API (приоритет: --dart-define > .env > дефолт)
  static String get apiBaseUrl {
    // Сначала проверяем --dart-define (для production деплоя)
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }
    // Если не задано через --dart-define, используем .env
    return dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
  }

  // Базовый URL фронтенда (для формирования ссылок инвайтов)
  static String get frontendBaseUrl {
    if (kIsWeb) {
      // На веб - используем текущий origin
      try {
        final uri = Uri.base;
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      } catch (e) {
        // Fallback на .env или дефолт
        return dotenv.env['FRONTEND_BASE_URL'] ?? 'http://localhost:1111';
      }
    } else {
      // На мобильных - из .env или дефолт
      return dotenv.env['FRONTEND_BASE_URL'] ?? 'https://qonbaq.com';
    }
  }

  /// Сформировать ссылку для инвайта
  static String buildInviteLink(String inviteCode) {
    return '$frontendBaseUrl/register?invite=$inviteCode';
  }
}
