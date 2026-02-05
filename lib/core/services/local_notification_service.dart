import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

/// Сервис для управления локальными уведомлениями
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Инициализация сервиса уведомлений
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      // Инициализируем timezone
      tz.initializeTimeZones();
      
      // Используем системный часовой пояс пользователя
      try {
        final timeZoneName = _getSystemTimeZoneName();
        if (timeZoneName.isNotEmpty) {
          tz.setLocalLocation(tz.getLocation(timeZoneName));
          debugPrint('✅ Используется системный часовой пояс: $timeZoneName');
        } else {
          // Если не удалось определить часовой пояс по смещению,
          // используем UTC как fallback
          debugPrint('⚠️ Не удалось определить часовой пояс по смещению, используется UTC');
          tz.setLocalLocation(tz.UTC);
        }
      } catch (e) {
        // Если не удалось определить системный часовой пояс,
        // используем UTC как fallback
        debugPrint('⚠️ Ошибка при установке часового пояса, используется UTC: $e');
        tz.setLocalLocation(tz.UTC);
      }

      // Настройки для Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // Настройки для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Инициализация
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Запрашиваем разрешения для Android 13+
      if (!kIsWeb) {
        await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      }

      _initialized = true;
      debugPrint('✅ LocalNotificationService инициализирован');
    } catch (e) {
      debugPrint('❌ Ошибка инициализации LocalNotificationService: $e');
    }
  }

  /// Получить имя системного часового пояса на основе смещения
  /// Использует смещение часового пояса для определения наиболее вероятного часового пояса
  String _getSystemTimeZoneName() {
    final offset = DateTime.now().timeZoneOffset;
    final offsetHours = offset.inHours;
    final offsetMinutes = offset.inMinutes % 60;
    
    // Определяем часовой пояс по смещению
    // Примечание: одно и то же смещение может соответствовать разным часовым поясам,
    // но для большинства случаев это работает корректно
    
    // UTC+0
    if (offsetHours == 0 && offsetMinutes == 0) {
      return 'UTC';
    }
    
    // Россия и СНГ (UTC+2 до UTC+12)
    if (offsetHours == 2 && offsetMinutes == 0) {
      return 'Europe/Kaliningrad';
    } else if (offsetHours == 3 && offsetMinutes == 0) {
      return 'Europe/Moscow';
    } else if (offsetHours == 4 && offsetMinutes == 0) {
      return 'Europe/Samara';
    } else if (offsetHours == 5 && offsetMinutes == 0) {
      return 'Asia/Yekaterinburg';
    } else if (offsetHours == 6 && offsetMinutes == 0) {
      return 'Asia/Omsk';
    } else if (offsetHours == 7 && offsetMinutes == 0) {
      return 'Asia/Krasnoyarsk';
    } else if (offsetHours == 8 && offsetMinutes == 0) {
      return 'Asia/Irkutsk';
    } else if (offsetHours == 9 && offsetMinutes == 0) {
      return 'Asia/Yakutsk';
    } else if (offsetHours == 10 && offsetMinutes == 0) {
      return 'Asia/Vladivostok';
    } else if (offsetHours == 11 && offsetMinutes == 0) {
      return 'Asia/Magadan';
    } else if (offsetHours == 12 && offsetMinutes == 0) {
      return 'Asia/Kamchatka';
    }
    
    // Попытка найти часовой пояс по общему смещению для других регионов
    // Используем наиболее распространенные часовые пояса
    if (offsetHours == 1 && offsetMinutes == 0) {
      return 'Europe/Paris'; // Центральная Европа
    } else if (offsetHours == -5 && offsetMinutes == 0) {
      return 'America/New_York'; // Восточное побережье США
    } else if (offsetHours == -8 && offsetMinutes == 0) {
      return 'America/Los_Angeles'; // Западное побережье США
    }
    
    // Если не удалось определить, возвращаем пустую строку
    // В этом случае будет использован UTC
    debugPrint('⚠️ Не удалось определить часовой пояс для смещения: ${offsetHours}:${offsetMinutes.toString().padLeft(2, '0')}');
    return '';
  }

  /// Обработчик нажатия на уведомление
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Уведомление нажато: ${response.payload}');
    // Здесь можно добавить навигацию при нажатии на уведомление
  }

  /// Показать уведомление о начале рабочего дня
  Future<void> showWorkDayStartedNotification({
    String? startTime,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'workday_channel',
        'Рабочий день',
        channelDescription: 'Уведомления о начале и завершении рабочего дня',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = 'Рабочий день начат';
      final body = startTime != null
          ? 'Рабочий день начат в $startTime'
          : 'Рабочий день начат';

      await _notifications.show(
        1,
        title,
        body,
        notificationDetails,
        payload: 'workday_started',
      );

      debugPrint('✅ Уведомление о начале рабочего дня отправлено');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления о начале рабочего дня: $e');
    }
  }

  /// Показать уведомление о завершении рабочего дня
  Future<void> showWorkDayEndedNotification({
    String? endTime,
  }) async {
    if (kIsWeb || !_initialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'workday_channel',
        'Рабочий день',
        channelDescription: 'Уведомления о начале и завершении рабочего дня',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final title = 'Рабочий день завершен';
      final body = endTime != null
          ? 'Рабочий день завершен в $endTime'
          : 'Рабочий день завершен';

      await _notifications.show(
        2,
        title,
        body,
        notificationDetails,
        payload: 'workday_ended',
      );

      debugPrint('✅ Уведомление о завершении рабочего дня отправлено');
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления о завершении рабочего дня: $e');
    }
  }
}
