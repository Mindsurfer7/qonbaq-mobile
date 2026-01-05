import '../../domain/entities/invite.dart';
import 'model.dart';

/// Модель приглашения для работы с данными
class InviteModel extends Invite implements Model {
  const InviteModel({
    required super.id,
    required super.code,
    super.maxUses,
    super.expiresAt,
    required super.createdAt,
  });

  /// Создание модели из JSON
  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      code: json['code'] as String,
      maxUses: json['maxUses'] as int?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Преобразование модели в доменную сущность
  Invite toEntity() {
    return Invite(
      id: id,
      code: code,
      maxUses: maxUses,
      expiresAt: expiresAt,
      createdAt: createdAt,
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      if (maxUses != null) 'maxUses': maxUses,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Модель ссылок для приглашения
class InviteLinksModel extends InviteLinks implements Model {
  const InviteLinksModel({
    required super.web,
    required super.deepLink,
  });

  /// Создание модели из JSON
  factory InviteLinksModel.fromJson(Map<String, dynamic> json) {
    return InviteLinksModel(
      web: json['web'] as String,
      deepLink: json['deepLink'] as String,
    );
  }

  /// Преобразование модели в доменную сущность
  InviteLinks toEntity() {
    return InviteLinks(
      web: web,
      deepLink: deepLink,
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'web': web,
      'deepLink': deepLink,
    };
  }
}

/// Модель результата создания приглашения
class CreateInviteResultModel extends CreateInviteResult implements Model {
  const CreateInviteResultModel({
    required super.invite,
    required super.links,
  });

  /// Создание модели из JSON
  factory CreateInviteResultModel.fromJson(Map<String, dynamic> json) {
    return CreateInviteResultModel(
      invite: InviteModel.fromJson(json['invite'] as Map<String, dynamic>),
      links: InviteLinksModel.fromJson(json['links'] as Map<String, dynamic>),
    );
  }

  /// Преобразование модели в доменную сущность
  CreateInviteResult toEntity() {
    return CreateInviteResult(
      invite: (invite as InviteModel).toEntity(),
      links: (links as InviteLinksModel).toEntity(),
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'invite': (invite as InviteModel).toJson(),
      'links': (links as InviteLinksModel).toJson(),
    };
  }
}







