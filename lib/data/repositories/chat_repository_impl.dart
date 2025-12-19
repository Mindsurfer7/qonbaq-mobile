import 'package:dartz/dartz.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/chat_remote_datasource.dart';
import '../datasources/chat_websocket_datasource.dart';
import '../repositories/repository_impl.dart';
import '../datasources/chat_remote_datasource_impl.dart';

/// Реализация репозитория чатов
/// Использует Remote DataSource и WebSocket DataSource
class ChatRepositoryImpl extends RepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatWebSocketDataSource? webSocketDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    this.webSocketDataSource,
  });

  @override
  Future<Either<Failure, List<Chat>>> getChats() async {
    try {
      final chats = await remoteDataSource.getChats();
      return Right(chats.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении чатов: $e'));
    }
  }

  @override
  Future<Either<Failure, Chat>> getOrCreateChatWithUser(
    String userId, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    try {
      final chat = await remoteDataSource.getOrCreateChatWithUser(
        userId,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      );
      return Right(chat.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении/создании чата: $e'));
    }
  }

  @override
  Future<Either<Failure, Chat>> getChatById(String chatId) async {
    try {
      final chat = await remoteDataSource.getChatById(chatId);
      return Right(chat.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении чата: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getChatMessages(String chatId) async {
    try {
      final messages = await remoteDataSource.getChatMessages(chatId);
      return Right(messages.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении сообщений: $e'));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(
    String chatId,
    String text, {
    String? replyToMessageId,
  }) async {
    try {
      final message =
          await remoteDataSource.sendMessage(chatId, text, replyToMessageId: replyToMessageId);
      return Right(message.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при отправке сообщения: $e'));
    }
  }

  // WebSocket методы

  @override
  Future<Either<Failure, void>> connectWebSocket(
    String chatId, {
    required void Function(Message) onNewMessage,
    required void Function(Message) onMessageSent,
    required void Function() onConnected,
    void Function(String)? onError,
    void Function()? onDisconnected,
  }) async {
    if (webSocketDataSource == null) {
      return Left(ServerFailure('WebSocket datasource не настроен'));
    }

    try {
      await webSocketDataSource!.connect(
        chatId,
        onMessage: (event) {
          switch (event.type) {
            case WebSocketEventType.connected:
              onConnected();
              break;
            case WebSocketEventType.newMessage:
              if (event.message != null) {
                onNewMessage(event.message!.toEntity());
              }
              break;
            case WebSocketEventType.messageSent:
              if (event.message != null) {
                onMessageSent(event.message!.toEntity());
              }
              break;
            case WebSocketEventType.error:
              if (event.error != null) {
                onError?.call(event.error!);
              }
              break;
            case WebSocketEventType.pong:
              // Игнорируем pong
              break;
          }
        },
        onError: (error) {
          onError?.call(error);
        },
        onConnected: onConnected,
        onDisconnected: onDisconnected,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка подключения к WebSocket: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectWebSocket() async {
    if (webSocketDataSource == null) {
      return Left(ServerFailure('WebSocket datasource не настроен'));
    }

    try {
      await webSocketDataSource!.disconnect();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка отключения от WebSocket: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessageViaWebSocket({
    required String text,
    String? taskId,
    String? replyToMessageId,
  }) async {
    if (webSocketDataSource == null) {
      return Left(ServerFailure('WebSocket datasource не настроен'));
    }

    try {
      await webSocketDataSource!.sendMessage(
        text: text,
        taskId: taskId,
        replyToMessageId: replyToMessageId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка отправки сообщения через WebSocket: $e'));
    }
  }

  @override
  bool get isWebSocketConnected {
    return webSocketDataSource?.isConnected ?? false;
  }
}

