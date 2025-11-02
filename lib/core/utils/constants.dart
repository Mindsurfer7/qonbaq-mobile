import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Общие константы приложения
class AppConstants {
  AppConstants._();

  // Название приложения
  static const String appName = 'Qonbaq';

  // Версия API (если нужно)
  static const String apiVersion = 'v1';

  // Базовый URL API (читается из .env файла)
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
}
