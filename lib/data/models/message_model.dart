import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../models/model.dart';
import 'user_model.dart';

/// Модель сообщения для работы с данными
class MessageModel extends Message implements Model {
  const MessageModel({
    required super.id,
    required super.text,
    required super.sender,
    required super.createdAt,
    required super.updatedAt,
    super.taskId,
    super.taskCommentId,
    super.task,
    super.isTaskComment,
    super.approvalId,
    super.approvalCommentId,
    super.approval,
    super.isApprovalComment,
    super.replyToMessage,
  });

  /// Создание модели из JSON
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // Парсинг отправителя
    final senderJson = json['sender'] as Map<String, dynamic>;
    // API возвращает структуру с firstName, lastName, patronymic, username
    // Формируем имя из этих полей или используем username
    String name = '';
    if (senderJson['firstName'] != null || senderJson['lastName'] != null) {
      final parts = <String>[];
      if (senderJson['lastName'] != null) {
        parts.add(senderJson['lastName'] as String);
      }
      if (senderJson['firstName'] != null) {
        parts.add(senderJson['firstName'] as String);
      }
      if (senderJson['patronymic'] != null) {
        parts.add(senderJson['patronymic'] as String);
      }
      name = parts.join(' ');
    } else if (senderJson['username'] != null) {
      name = senderJson['username'] as String;
    } else {
      name = senderJson['email'] as String? ?? '';
    }

    final sender = User(
      id: senderJson['id'] as String,
      name: name,
      email: senderJson['email'] as String? ?? '',
    );

    // Парсинг задачи (если есть)
    MessageTask? task;
    if (json['task'] != null) {
      final taskJson = json['task'] as Map<String, dynamic>;
      task = MessageTask(
        id: taskJson['id'] as String,
        title: taskJson['title'] as String,
      );
    }

    // Парсинг согласования (если есть)
    MessageApproval? approval;
    if (json['approval'] != null) {
      final approvalJson = json['approval'] as Map<String, dynamic>;
      approval = MessageApproval(
        id: approvalJson['id'] as String,
        title: approvalJson['title'] as String,
      );
    }

    // Парсинг реплая (если есть)
    ReplyToMessage? replyToMessage;
    if (json['replyToMessage'] != null) {
      final replyJson = json['replyToMessage'] as Map<String, dynamic>;
      MessageTask? replyTask;
      if (replyJson['task'] != null) {
        final replyTaskJson = replyJson['task'] as Map<String, dynamic>;
        replyTask = MessageTask(
          id: replyTaskJson['id'] as String,
          title: replyTaskJson['title'] as String,
        );
      }
      MessageApproval? replyApproval;
      if (replyJson['approval'] != null) {
        final replyApprovalJson = replyJson['approval'] as Map<String, dynamic>;
        replyApproval = MessageApproval(
          id: replyApprovalJson['id'] as String,
          title: replyApprovalJson['title'] as String,
        );
      }
      replyToMessage = ReplyToMessage(
        id: replyJson['id'] as String,
        text: replyJson['text'] as String,
        taskId: replyJson['taskId'] as String?,
        task: replyTask,
        isTaskComment: replyJson['isTaskComment'] as bool? ?? false,
        approvalId: replyJson['approvalId'] as String?,
        approval: replyApproval,
        isApprovalComment: replyJson['isApprovalComment'] as bool? ?? false,
      );
    }

    return MessageModel(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: sender,
      // В некоторых ответах (например, вложенные/упрощенные DTO) createdAt/updatedAt могут отсутствовать.
      // Не падаем на парсинге — подставляем epoch.
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      taskId: json['taskId'] as String?,
      taskCommentId: json['taskCommentId'] as String?,
      task: task,
      isTaskComment: json['isTaskComment'] as bool? ?? false,
      approvalId: json['approvalId'] as String?,
      approvalCommentId: json['approvalCommentId'] as String?,
      approval: approval,
      isApprovalComment: json['isApprovalComment'] as bool? ?? false,
      replyToMessage: replyToMessage,
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': UserModel.fromEntity(sender).toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (taskId != null) 'taskId': taskId,
      if (taskCommentId != null) 'taskCommentId': taskCommentId,
      if (task != null)
        'task': {
          'id': task!.id,
          'title': task!.title,
        },
      'isTaskComment': isTaskComment,
      if (approvalId != null) 'approvalId': approvalId,
      if (approvalCommentId != null) 'approvalCommentId': approvalCommentId,
      if (approval != null)
        'approval': {
          'id': approval!.id,
          'title': approval!.title,
        },
      'isApprovalComment': isApprovalComment,
      if (replyToMessage != null)
        'replyToMessage': {
          'id': replyToMessage!.id,
          'text': replyToMessage!.text,
          if (replyToMessage!.taskId != null)
            'taskId': replyToMessage!.taskId,
          if (replyToMessage!.task != null)
            'task': {
              'id': replyToMessage!.task!.id,
              'title': replyToMessage!.task!.title,
            },
          'isTaskComment': replyToMessage!.isTaskComment,
          if (replyToMessage!.approvalId != null)
            'approvalId': replyToMessage!.approvalId,
          if (replyToMessage!.approval != null)
            'approval': {
              'id': replyToMessage!.approval!.id,
              'title': replyToMessage!.approval!.title,
            },
          'isApprovalComment': replyToMessage!.isApprovalComment,
        },
    };
  }

  /// Преобразование в JSON для отправки сообщения
  Map<String, dynamic> toSendJson() {
    return {
      'text': text,
      if (taskId != null) 'taskId': taskId,
      if (approvalId != null) 'approvalId': approvalId,
      if (replyToMessage != null) 'replyToMessageId': replyToMessage!.id,
    };
  }

  /// Преобразование модели в доменную сущность
  Message toEntity() {
    return Message(
      id: id,
      text: text,
      sender: sender,
      createdAt: createdAt,
      updatedAt: updatedAt,
      taskId: taskId,
      taskCommentId: taskCommentId,
      task: task,
      isTaskComment: isTaskComment,
      approvalId: approvalId,
      approvalCommentId: approvalCommentId,
      approval: approval,
      isApprovalComment: isApprovalComment,
      replyToMessage: replyToMessage,
    );
  }

  /// Создание модели из доменной сущности
  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      text: message.text,
      sender: message.sender,
      createdAt: message.createdAt,
      updatedAt: message.updatedAt,
      taskId: message.taskId,
      taskCommentId: message.taskCommentId,
      task: message.task,
      isTaskComment: message.isTaskComment,
      approvalId: message.approvalId,
      approvalCommentId: message.approvalCommentId,
      approval: message.approval,
      isApprovalComment: message.isApprovalComment,
      replyToMessage: message.replyToMessage,
    );
  }
}

