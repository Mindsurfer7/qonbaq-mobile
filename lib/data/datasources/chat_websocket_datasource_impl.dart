import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/chat_websocket_datasource.dart';
import '../models/message_model.dart';

/// Реализация WebSocket источника данных для чатов
class ChatWebSocketDataSourceImpl implements ChatWebSocketDataSource {
  WebSocketChannel? _channel;
  Timer? _pingTimer;
  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected && _channel != null;

  /// Получить WebSocket URL
  String _getWebSocketUrl(String chatId) {
    final baseUrl = AppConstants.apiBaseUrl;
    // Преобразуем http:// в ws:// или https:// в wss://
    final wsBaseUrl = baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
    final token = TokenStorage.instance.getAccessToken();
    
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }

    return '$wsBaseUrl/api/chats/$chatId/ws?token=$token';
  }

  @override
  Future<void> connect(
    String chatId, {
    required WebSocketMessageCallback onMessage,
    required WebSocketErrorCallback onError,
    required WebSocketConnectionCallback onConnected,
    WebSocketDisconnectionCallback? onDisconnected,
  }) async {
    try {
      // Закрываем существующее соединение, если есть
      await disconnect();

      final url = _getWebSocketUrl(chatId);
      final uri = Uri.parse(url);

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data as String) as Map<String, dynamic>;
            final eventType = json['type'] as String;

            switch (eventType) {
              case 'connected':
                _isConnected = true;
                onConnected();
                onMessage(WebSocketServerEvent(
                  type: WebSocketEventType.connected,
                  chatId: json['chatId'] as String?,
                ));
                // Запускаем ping каждые 30 секунд
                _startPingTimer();
                break;

              case 'new_message':
                final messageJson = json['message'] as Map<String, dynamic>;
                final message = MessageModel.fromJson(messageJson);
                onMessage(WebSocketServerEvent(
                  type: WebSocketEventType.newMessage,
                  message: message,
                ));
                break;

              case 'message_sent':
                final messageJson = json['message'] as Map<String, dynamic>;
                final message = MessageModel.fromJson(messageJson);
                onMessage(WebSocketServerEvent(
                  type: WebSocketEventType.messageSent,
                  message: message,
                ));
                break;

              case 'pong':
                onMessage(WebSocketServerEvent(
                  type: WebSocketEventType.pong,
                ));
                break;

              case 'error':
                final error = json['error'] as String? ?? 'Неизвестная ошибка';
                final details = json['details'] as List<dynamic>?;
                onError(error);
                onMessage(WebSocketServerEvent(
                  type: WebSocketEventType.error,
                  error: error,
                  details: details?.map((e) => e.toString()).toList(),
                ));
                break;

              default:
                print('⚠️ Неизвестный тип события WebSocket: $eventType');
            }
          } catch (e) {
            print('❌ Ошибка при парсинге сообщения WebSocket: $e');
            onError('Ошибка при обработке сообщения: $e');
          }
        },
        onError: (error) {
          _isConnected = false;
          _stopPingTimer();
          onError('Ошибка WebSocket: $error');
          onDisconnected?.call();
        },
        onDone: () {
          _isConnected = false;
          _stopPingTimer();
          onDisconnected?.call();
        },
        cancelOnError: false,
      );
    } catch (e) {
      _isConnected = false;
      throw Exception('Ошибка подключения к WebSocket: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _stopPingTimer();
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  @override
  Future<void> sendMessage({
    required String text,
    String? taskId,
    String? approvalId,
    String? replyToMessageId,
  }) async {
    if (!isConnected || _channel == null) {
      throw Exception('WebSocket не подключен');
    }

    final event = {
      'type': 'send_message',
      'message': {
        'text': text,
        if (taskId != null) 'taskId': taskId,
        if (approvalId != null) 'approvalId': approvalId,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      },
    };

    try {
      _channel!.sink.add(jsonEncode(event));
    } catch (e) {
      throw Exception('Ошибка при отправке сообщения: $e');
    }
  }

  @override
  Future<void> sendPing() async {
    if (!isConnected || _channel == null) {
      return;
    }

    final event = {'type': 'ping'};
    try {
      _channel!.sink.add(jsonEncode(event));
    } catch (e) {
      print('⚠️ Ошибка при отправке ping: $e');
    }
  }

  /// Запустить таймер для отправки ping
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      sendPing();
    });
  }

  /// Остановить таймер ping
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
}

