import 'package:dartz/dartz.dart';
import '../entities/chat.dart';
import '../entities/message.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с чатами
/// Реализация находится в data слое
abstract class ChatRepository extends Repository {
  /// Получить список чатов
  Future<Either<Failure, List<Chat>>> getChats();

  /// Получить список анонимных чатов бизнеса
  Future<Either<Failure, List<Chat>>> getAnonymousChats(
    String businessId, {
    int page = 1,
    int limit = 20,
  });

  /// Получить/создать чат с пользователем
  Future<Either<Failure, Chat>> getOrCreateChatWithUser(
    String userId, {
    String? currentUserId,
    String? currentUserName,
  });

  /// Получить информацию о чате по ID
  Future<Either<Failure, Chat>> getChatById(String chatId);

  /// Получить сообщения чата
  Future<Either<Failure, List<Message>>> getChatMessages(String chatId);

  /// Отправить сообщение в чат (REST API - для обратной совместимости)
  Future<Either<Failure, Message>> sendMessage(
    String chatId,
    String text, {
    String? replyToMessageId,
    String? taskId,
    String? approvalId,
  });

  // WebSocket методы

  /// Подключиться к WebSocket чата
  Future<Either<Failure, void>> connectWebSocket(
    String chatId, {
    required void Function(Message) onNewMessage,
    required void Function(Message) onMessageSent,
    required void Function() onConnected,
    void Function(String)? onError,
    void Function()? onDisconnected,
  });

  /// Отключиться от WebSocket чата
  Future<Either<Failure, void>> disconnectWebSocket();

  /// Отправить сообщение через WebSocket
  Future<Either<Failure, void>> sendMessageViaWebSocket({
    required String text,
    String? taskId,
    String? approvalId,
    String? replyToMessageId,
  });

  /// Проверить, подключен ли WebSocket
  bool get isWebSocketConnected;
}

