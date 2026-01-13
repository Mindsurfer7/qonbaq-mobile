import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/task_comment.dart';
import '../../domain/entities/user_profile.dart';

/// Универсальная модель для отображения комментария
/// Используется для унификации работы с комментариями разных типов
class CommentItem {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileUser? user;

  const CommentItem({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  /// Создает CommentItem из ApprovalComment
  factory CommentItem.fromApprovalComment(ApprovalComment comment) {
    return CommentItem(
      id: comment.id,
      text: comment.text,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      user: comment.user,
    );
  }

  /// Создает CommentItem из TaskComment
  factory CommentItem.fromTaskComment(TaskComment comment) {
    return CommentItem(
      id: comment.id,
      text: comment.text,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      user: comment.user,
    );
  }

  /// Создает список CommentItem из списка ApprovalComment
  static List<CommentItem> fromApprovalComments(List<ApprovalComment> comments) {
    return comments.map((c) => CommentItem.fromApprovalComment(c)).toList();
  }

  /// Создает список CommentItem из списка TaskComment
  static List<CommentItem> fromTaskComments(List<TaskComment> comments) {
    return comments.map((c) => CommentItem.fromTaskComment(c)).toList();
  }
}
