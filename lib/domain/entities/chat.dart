import '../entities/entity.dart';
import 'user.dart';
import 'message.dart';
import 'business.dart';

/// Тип чата
enum ChatType {
  userToUser,
  anonymousBusiness;

  static ChatType fromString(String value) {
    switch (value) {
      case 'USER_TO_USER':
        return ChatType.userToUser;
      case 'ANONYMOUS_BUSINESS':
        return ChatType.anonymousBusiness;
      default:
        throw ArgumentError('Unknown ChatType: $value');
    }
  }

  String toJson() {
    switch (this) {
      case ChatType.userToUser:
        return 'USER_TO_USER';
      case ChatType.anonymousBusiness:
        return 'ANONYMOUS_BUSINESS';
    }
  }
}

/// Доменная сущность чата
class Chat extends Entity {
  final String id;
  final ChatType chatType;
  
  // Для user-to-user чатов
  final User? participant1;
  final User? participant2;
  
  // Для анонимных чатов
  final String? businessId;
  final String? anonymousHash;
  final Business? business;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Последнее сообщение (для списка чатов)
  final Message? lastMessage;
  
  // Информация о задаче (если последнее сообщение связано с задачей)
  final MessageTask? lastMessageTask;
  
  // Информация о согласовании (если последнее сообщение связано с согласованием)
  final MessageApproval? lastMessageApproval;
  
  // Количество непрочитанных сообщений (для анонимных чатов)
  final int unreadCount;

  const Chat({
    required this.id,
    required this.chatType,
    this.participant1,
    this.participant2,
    this.businessId,
    this.anonymousHash,
    this.business,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.lastMessageTask,
    this.lastMessageApproval,
    this.unreadCount = 0,
  });

  /// Проверка, является ли чат анонимным
  bool get isAnonymous => chatType == ChatType.anonymousBusiness;

  /// Проверка, является ли чат user-to-user
  bool get isUserToUser => chatType == ChatType.userToUser;

  /// Получить собеседника для указанного пользователя (только для user-to-user чатов)
  User? getInterlocutor(String currentUserId) {
    if (!isUserToUser || participant1 == null || participant2 == null) {
      return null;
    }
    return participant1!.id == currentUserId ? participant2 : participant1;
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
  String toString() {
    if (isAnonymous) {
      return 'Chat(id: $id, type: anonymousBusiness, businessId: $businessId, anonymousHash: $anonymousHash)';
    } else {
      return 'Chat(id: $id, type: userToUser, participant1: ${participant1?.name}, participant2: ${participant2?.name})';
    }
  }
}


