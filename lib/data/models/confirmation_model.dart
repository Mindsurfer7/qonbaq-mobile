import '../../domain/entities/confirmation.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';

/// Модель подтверждения
class ConfirmationModel extends Confirmation implements Model {
  const ConfirmationModel({
    required super.id,
    required super.approvalId,
    required super.userId,
    required super.isConfirmed,
    super.amount,
    super.comment,
    required super.createdAt,
    required super.updatedAt,
    super.user,
  });

  factory ConfirmationModel.fromJson(Map<String, dynamic> json) {
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

    // Поддерживаем оба варианта: createdAt и confirmedAt
    final createdAtStr = json['createdAt'] as String? ?? json['confirmedAt'] as String?;
    final updatedAtStr = json['updatedAt'] as String? ?? json['confirmedAt'] as String?;
    
    if (createdAtStr == null) {
      throw FormatException('Поле createdAt или confirmedAt обязательно для Confirmation');
    }

    return ConfirmationModel(
      id: json['id'] as String,
      approvalId: json['approvalId'] as String,
      userId: json['userId'] as String,
      isConfirmed: json['isConfirmed'] as bool,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: updatedAtStr != null ? DateTime.parse(updatedAtStr) : DateTime.parse(createdAtStr),
      user: user,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'approvalId': approvalId,
      'userId': userId,
      'isConfirmed': isConfirmed,
      if (amount != null) 'amount': amount,
      if (comment != null) 'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Confirmation toEntity() {
    return Confirmation(
      id: id,
      approvalId: approvalId,
      userId: userId,
      isConfirmed: isConfirmed,
      amount: amount,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
    );
  }

  factory ConfirmationModel.fromEntity(Confirmation confirmation) {
    return ConfirmationModel(
      id: confirmation.id,
      approvalId: confirmation.approvalId,
      userId: confirmation.userId,
      isConfirmed: confirmation.isConfirmed,
      amount: confirmation.amount,
      comment: confirmation.comment,
      createdAt: confirmation.createdAt,
      updatedAt: confirmation.updatedAt,
      user: confirmation.user,
    );
  }
}
