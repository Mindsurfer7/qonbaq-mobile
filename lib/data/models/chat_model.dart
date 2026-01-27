import '../../domain/entities/chat.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/business.dart';
import '../models/model.dart';
import 'user_model.dart';
import 'message_model.dart';
import 'business_model.dart';

/// Модель чата для работы с данными
class ChatModel extends Chat implements Model {
  const ChatModel({
    required super.id,
    required super.chatType,
    super.participant1,
    super.participant2,
    super.businessId,
    super.anonymousHash,
    super.business,
    required super.createdAt,
    required super.updatedAt,
    super.lastMessage,
    super.lastMessageTask,
    super.lastMessageApproval,
    super.unreadCount = 0,
  });

  /// Создание модели из JSON
  /// Если передан currentUserId и currentUserName, используется структура с otherUser
  factory ChatModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    String? currentUserName,
  }) {
    // Определяем тип чата
    final chatType = ChatType.fromString(json['chatType'] as String? ?? 'USER_TO_USER');
    
    User? participant1;
    User? participant2;
    String? businessId;
    String? anonymousHash;
    Business? business;

    // Парсим в зависимости от типа чата
    if (chatType == ChatType.userToUser) {
      // Если есть otherUser, значит API вернул упрощенную структуру
      if (json.containsKey('otherUser') &&
          currentUserId != null &&
          currentUserName != null) {
        // Текущий пользователь - participant1
        participant1 = User(
          id: currentUserId,
          name: currentUserName,
          email: '', // Email не предоставляется в этом контексте
        );

        // Собеседник из otherUser - participant2
        final otherUserJson = json['otherUser'] as Map<String, dynamic>;
        // Формируем имя из firstName, lastName, patronymic или используем username
        String name = '';
        if (otherUserJson['firstName'] != null ||
            otherUserJson['lastName'] != null) {
          final parts = <String>[];
          if (otherUserJson['lastName'] != null) {
            parts.add(otherUserJson['lastName'] as String);
          }
          if (otherUserJson['firstName'] != null) {
            parts.add(otherUserJson['firstName'] as String);
          }
          if (otherUserJson['patronymic'] != null) {
            parts.add(otherUserJson['patronymic'] as String);
          }
          name = parts.join(' ');
        } else if (otherUserJson['username'] != null) {
          name = otherUserJson['username'] as String;
        } else {
          name = otherUserJson['email'] as String? ?? '';
        }

        participant2 = User(
          id: otherUserJson['id'] as String,
          name: name,
          email: otherUserJson['email'] as String? ?? '',
        );
      } else if (json.containsKey('participant1') && json.containsKey('participant2')) {
        // Стандартная структура с participant1 и participant2
        final participant1Json = json['participant1'] as Map<String, dynamic>;
        participant1 = UserModel.fromJson(participant1Json).toEntity();

        final participant2Json = json['participant2'] as Map<String, dynamic>;
        participant2 = UserModel.fromJson(participant2Json).toEntity();
      }
    } else if (chatType == ChatType.anonymousBusiness) {
      // Анонимный чат
      businessId = json['businessId'] as String?;
      anonymousHash = json['anonymousHash'] as String?;
      
      if (json['business'] != null) {
        business = BusinessModel.fromJson(json['business'] as Map<String, dynamic>).toEntity();
      }
    }

    // Парсинг последнего сообщения (если есть)
    Message? lastMessage;
    if (json['lastMessage'] != null) {
      final lastMessageJson = json['lastMessage'] as Map<String, dynamic>;
      lastMessage = MessageModel.fromJson(lastMessageJson).toEntity();
    }

    // Парсинг задачи последнего сообщения (если есть)
    MessageTask? lastMessageTask;
    if (json['lastMessageTask'] != null) {
      final taskJson = json['lastMessageTask'] as Map<String, dynamic>;
      lastMessageTask = MessageTask(
        id: taskJson['id'] as String,
        title: taskJson['title'] as String,
      );
    }

    // Парсинг согласования последнего сообщения (если есть)
    MessageApproval? lastMessageApproval;
    if (json['lastMessageApproval'] != null) {
      final approvalJson = json['lastMessageApproval'] as Map<String, dynamic>;
      lastMessageApproval = MessageApproval(
        id: approvalJson['id'] as String,
        title: approvalJson['title'] as String,
      );
    }

    return ChatModel(
      id: json['id'] as String,
      chatType: chatType,
      participant1: participant1,
      participant2: participant2,
      businessId: businessId,
      anonymousHash: anonymousHash,
      business: business,
      // В некоторых ответах (например, вложенные/упрощенные DTO) createdAt/updatedAt могут отсутствовать.
      // Не падаем на парсинге — подставляем epoch.
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lastMessage: lastMessage,
      lastMessageTask: lastMessageTask,
      lastMessageApproval: lastMessageApproval,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatType': chatType.toJson(),
      if (participant1 != null)
        'participant1': UserModel.fromEntity(participant1!).toJson(),
      if (participant2 != null)
        'participant2': UserModel.fromEntity(participant2!).toJson(),
      if (businessId != null) 'businessId': businessId,
      if (anonymousHash != null) 'anonymousHash': anonymousHash,
      if (business != null)
        'business': BusinessModel.fromEntity(business!).toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastMessage != null)
        'lastMessage': MessageModel.fromEntity(lastMessage!).toJson(),
      if (lastMessageTask != null)
        'lastMessageTask': {
          'id': lastMessageTask!.id,
          'title': lastMessageTask!.title,
        },
      if (lastMessageApproval != null)
        'lastMessageApproval': {
          'id': lastMessageApproval!.id,
          'title': lastMessageApproval!.title,
        },
      'unreadCount': unreadCount,
    };
  }

  /// Преобразование модели в доменную сущность
  Chat toEntity() {
    return Chat(
      id: id,
      chatType: chatType,
      participant1: participant1,
      participant2: participant2,
      businessId: businessId,
      anonymousHash: anonymousHash,
      business: business,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessage: lastMessage,
      lastMessageTask: lastMessageTask,
      lastMessageApproval: lastMessageApproval,
      unreadCount: unreadCount,
    );
  }

  /// Создание модели из доменной сущности
  factory ChatModel.fromEntity(Chat chat) {
    return ChatModel(
      id: chat.id,
      chatType: chat.chatType,
      participant1: chat.participant1,
      participant2: chat.participant2,
      businessId: chat.businessId,
      anonymousHash: chat.anonymousHash,
      business: chat.business,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
      lastMessage: chat.lastMessage,
      lastMessageTask: chat.lastMessageTask,
      lastMessageApproval: chat.lastMessageApproval,
      unreadCount: chat.unreadCount,
    );
  }
}
