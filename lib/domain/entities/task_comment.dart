import '../entities/entity.dart';
import 'user_profile.dart';

/// Доменная сущность комментария к задаче
class TaskComment extends Entity {
  final String id;
  final String taskId;
  final String userId;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProfileUser? user;

  const TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskComment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TaskComment(id: $id, text: ${text.substring(0, text.length > 20 ? 20 : text.length)}...)';
}






