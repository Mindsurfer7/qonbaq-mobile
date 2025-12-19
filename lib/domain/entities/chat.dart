import '../entities/entity.dart';
import 'user.dart';
import 'message.dart';

/// Доменная сущность чата
class Chat extends Entity {
  final String id;
  final User participant1;
  final User participant2;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Последнее сообщение (для списка чатов)
  final Message? lastMessage;
  
  // Информация о задаче (если последнее сообщение связано с задачей)
  final MessageTask? lastMessageTask;
  
  // Информация о согласовании (если последнее сообщение связано с согласованием)
  final MessageApproval? lastMessageApproval;

  const Chat({
    required this.id,
    required this.participant1,
    required this.participant2,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTask,
    this.lastMessageApproval,
  });

  /// Получить собеседника для указанного пользователя
  User getInterlocutor(String currentUserId) {
    return participant1.id == currentUserId ? participant2 : participant1;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Chat(id: $id, participant1: ${participant1.name}, participant2: ${participant2.name})';
}


