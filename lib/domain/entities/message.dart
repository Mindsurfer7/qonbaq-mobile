import '../entities/entity.dart';
import 'user.dart';

/// Информация о задаче в сообщении
class MessageTask extends Entity {
  final String id;
  final String title;

  const MessageTask({required this.id, required this.title});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTask &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Информация о согласовании в сообщении
class MessageApproval extends Entity {
  final String id;
  final String title;

  const MessageApproval({required this.id, required this.title});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageApproval &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Сообщение, на которое идет ответ (reply)
class ReplyToMessage extends Entity {
  final String id;
  final String text;
  final String? taskId;
  final MessageTask? task;
  final bool isTaskComment;
  final String? approvalId;
  final MessageApproval? approval;
  final bool isApprovalComment;

  const ReplyToMessage({
    required this.id,
    required this.text,
    this.taskId,
    this.task,
    this.isTaskComment = false,
    this.approvalId,
    this.approval,
    this.isApprovalComment = false,
  });
}

/// Доменная сущность сообщения чата
class Message extends Entity {
  final String id;
  final String? chatId;
  final String text;
  final User? sender; // null для анонимных сообщений
  final DateTime createdAt;
  final DateTime updatedAt;

  // Информация о задаче
  final String? taskId;
  final String? taskCommentId;
  final MessageTask? task;
  final bool isTaskComment;

  // Информация о согласовании
  final String? approvalId;
  final String? approvalCommentId;
  final MessageApproval? approval;
  final bool isApprovalComment;

  // Информация о реплае
  final ReplyToMessage? replyToMessage;

  const Message({
    required this.id,
    this.chatId,
    required this.text,
    this.sender,
    required this.createdAt,
    required this.updatedAt,
    this.taskId,
    this.taskCommentId,
    this.task,
    this.isTaskComment = false,
    this.approvalId,
    this.approvalCommentId,
    this.approval,
    this.isApprovalComment = false,
    this.replyToMessage,
  });

  /// Проверка, является ли сообщение анонимным
  bool get isAnonymous => sender == null;

  /// Проверка, является ли сообщение от бизнеса
  bool get isFromBusiness => sender != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Message(id: $id, text: ${text.length > 30 ? text.substring(0, 30) : text}..., isAnonymous: $isAnonymous, isTaskComment: $isTaskComment, isApprovalComment: $isApprovalComment)';
}
