import '../../domain/entities/task_comment.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';

/// Модель комментария к задаче
class TaskCommentModel extends TaskComment implements Model {
  const TaskCommentModel({
    required super.id,
    required super.taskId,
    required super.userId,
    required super.text,
    required super.createdAt,
    required super.updatedAt,
    super.user,
  });

  factory TaskCommentModel.fromJson(Map<String, dynamic> json) {
    ProfileUser? user;
    if (json['user'] != null) {
      final userJson = json['user'] as Map<String, dynamic>;
      user = ProfileUser(
        id: userJson['id'] as String,
        email: userJson['email'] as String,
        firstName: userJson['firstName'] as String?,
        lastName: userJson['lastName'] as String?,
        patronymic: userJson['patronymic'] as String?,
        phone: userJson['phone'] as String?,
      );
    }

    return TaskCommentModel(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: user,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'userId': userId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (user != null)
        'user': {
          'id': user!.id,
          'email': user!.email,
          if (user!.firstName != null) 'firstName': user!.firstName,
          if (user!.lastName != null) 'lastName': user!.lastName,
          if (user!.patronymic != null) 'patronymic': user!.patronymic,
          if (user!.phone != null) 'phone': user!.phone,
        },
    };
  }

  TaskComment toEntity() {
    return TaskComment(
      id: id,
      taskId: taskId,
      userId: userId,
      text: text,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }

  factory TaskCommentModel.fromEntity(TaskComment comment) {
    return TaskCommentModel(
      id: comment.id,
      taskId: comment.taskId,
      userId: comment.userId,
      text: comment.text,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      user: comment.user,
    );
  }

  /// Преобразование в JSON для создания комментария
  Map<String, dynamic> toCreateJson() {
    return {
      'text': text,
    };
  }

  /// Преобразование в JSON для обновления комментария
  Map<String, dynamic> toUpdateJson() {
    return {
      'text': text,
    };
  }
}






