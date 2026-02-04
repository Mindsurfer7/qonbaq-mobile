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
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));

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
