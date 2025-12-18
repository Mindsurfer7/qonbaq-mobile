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

  /// Отправить сообщение в чат
  Future<Either<Failure, Message>> sendMessage(
    String chatId,
    String text, {
    String? replyToMessageId,
  });
}

