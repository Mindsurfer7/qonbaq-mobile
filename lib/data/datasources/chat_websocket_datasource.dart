import 'dart:async';
import '../datasources/datasource.dart';
import '../models/message_model.dart';

/// Типы событий WebSocket
enum WebSocketEventType {
  connected,
  newMessage,
  messageSent,
  pong,
  error,
}

/// Событие от сервера
class WebSocketServerEvent {
  final WebSocketEventType type;
  final MessageModel? message;
  final String? chatId;
  final String? error;
  final List<String>? details;

  WebSocketServerEvent({
    required this.type,
    this.message,
    this.chatId,
    this.error,
    this.details,
  });
}

/// Событие от клиента
class WebSocketClientEvent {
  final String type;
  final Map<String, dynamic>? data;

  WebSocketClientEvent({
    required this.type,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (data != null) ...data!,
    };
  }
}

/// Callback для обработки событий
typedef WebSocketMessageCallback = void Function(WebSocketServerEvent event);
typedef WebSocketErrorCallback = void Function(String error);
typedef WebSocketConnectionCallback = void Function();
typedef WebSocketDisconnectionCallback = void Function();

/// WebSocket источник данных для чатов
abstract class ChatWebSocketDataSource extends DataSource {
  /// Подключиться к WebSocket чата
  Future<void> connect(
    String chatId, {
    required WebSocketMessageCallback onMessage,
    required WebSocketErrorCallback onError,
    required WebSocketConnectionCallback onConnected,
    WebSocketDisconnectionCallback? onDisconnected,
  });

  /// Отключиться от WebSocket
  Future<void> disconnect();

  /// Отправить сообщение через WebSocket
  Future<void> sendMessage({
    required String text,
    String? taskId,
    String? approvalId,
    String? replyToMessageId,
  });

  /// Отправить ping для keep-alive
  Future<void> sendPing();

  /// Проверить, подключен ли WebSocket
  bool get isConnected;
}

