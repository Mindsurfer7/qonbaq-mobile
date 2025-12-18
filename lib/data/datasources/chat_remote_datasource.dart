import '../datasources/datasource.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

/// Удаленный источник данных для чатов (API)
abstract class ChatRemoteDataSource extends DataSource {
  /// Получить список чатов с последним сообщением и информацией о задаче
  Future<List<ChatModel>> getChats();

  /// Получить/создать чат с пользователем
  Future<ChatModel> getOrCreateChatWithUser(
    String userId, {
    String? currentUserId,
    String? currentUserName,
  });

  /// Получить информацию о чате по ID
  Future<ChatModel> getChatById(String chatId);

  /// Получить сообщения чата
  Future<List<MessageModel>> getChatMessages(String chatId);

  /// Отправить сообщение в чат
  Future<MessageModel> sendMessage(String chatId, String text, {String? replyToMessageId});
}

