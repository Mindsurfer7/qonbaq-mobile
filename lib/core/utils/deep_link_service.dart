import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Сервис для обработки deep links
class DeepLinkService {
  static DeepLinkService? _instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _pendingInviteCode;

  DeepLinkService._();

  static DeepLinkService get instance {
    _instance ??= DeepLinkService._();
    return _instance!;
  }

  /// Получить код приглашения, который был передан через deep link
  String? get pendingInviteCode => _pendingInviteCode;

  /// Очистить код приглашения после использования
  void clearInviteCode() {
    _pendingInviteCode = null;
  }

  /// Установить код приглашения
  void setInviteCode(String? code) {
    _pendingInviteCode = code;
  }

  /// Извлечь invite код из URL (для веб-платформы)
  String? extractInviteFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    
    try {
      final uri = Uri.parse(url);
      final inviteCode = uri.queryParameters['invite'];
      if (inviteCode != null && inviteCode.isNotEmpty) {
        _pendingInviteCode = inviteCode;
        print('Код приглашения извлечен из URL: $inviteCode');
        return inviteCode;
      }
    } catch (e) {
      print('Ошибка парсинга URL: $e');
    }
    return null;
  }

  /// Инициализация обработки deep links
  Future<void> initialize() async {
    // Обработка deep link, когда приложение запускается через deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      } else if (kIsWeb) {
        // Для веб-платформы: пытаемся получить текущий URL через uriLinkStream
        // Это сработает, если приложение уже запущено
        _checkWebUrl();
      }
    } catch (e) {
      print('Ошибка получения initial link: $e');
      if (kIsWeb) {
        _checkWebUrl();
      }
    }

    // Обработка deep links, когда приложение уже запущено
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('Ошибка обработки deep link: $err');
      },
    );
  }

  /// Проверка URL на веб-платформе
  void _checkWebUrl() {
    if (!kIsWeb) return;
    
    // На веб-платформе app_links должен автоматически обрабатывать изменения URL
    // Но для начальной загрузки с query параметрами нужно проверить текущий URL
    // Это делается через uriLinkStream, который уже настроен в initialize()
  }

  /// Получить текущий URL и извлечь invite код (для веб-платформы)
  Future<String?> checkCurrentUrlForInvite() async {
    if (!kIsWeb) return null;
    
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        return uri.queryParameters['invite'];
      }
    } catch (e) {
      print('Ошибка проверки текущего URL: $e');
    }
    return null;
  }

  /// Обработка deep link
  void _handleDeepLink(Uri uri) {
    print('Получен deep link: $uri');
    
    // Проверяем схему или HTTP/HTTPS для веб
    if (uri.scheme == 'qonbaq' || 
        (kIsWeb && (uri.scheme == 'http' || uri.scheme == 'https'))) {
      // Извлекаем код приглашения из query параметров
      final inviteCode = uri.queryParameters['invite'];
      if (inviteCode != null && inviteCode.isNotEmpty) {
        _pendingInviteCode = inviteCode;
        print('Код приглашения извлечен: $inviteCode');
      }
    }
  }

  /// Освобождение ресурсов
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
}

