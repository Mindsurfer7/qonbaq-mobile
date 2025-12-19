import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';

/// Модель комментария к согласованию
class ApprovalCommentModel extends ApprovalComment implements Model {
  const ApprovalCommentModel({
    required super.id,
    required super.approvalId,
    required super.text,
    required super.userId,
    required super.createdAt,
    required super.updatedAt,
    super.user,
  });

  factory ApprovalCommentModel.fromJson(Map<String, dynamic> json) {
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

    return ApprovalCommentModel(
      id: json['id'] as String,
      approvalId: json['approvalId'] as String,
      text: json['text'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: user,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approvalId': approvalId,
      'text': text,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ApprovalComment toEntity() {
    return ApprovalComment(
      id: id,
      approvalId: approvalId,
      text: text,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }

  factory ApprovalCommentModel.fromEntity(ApprovalComment comment) {
    return ApprovalCommentModel(
      id: comment.id,
      approvalId: comment.approvalId,
      text: comment.text,
      userId: comment.userId,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
      user: comment.user,
    );
  }
}

