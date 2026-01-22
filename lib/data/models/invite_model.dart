import '../../domain/entities/invite.dart';
import 'model.dart';

/// Модель приглашения для работы с данными
class InviteModel extends Invite implements Model {
  const InviteModel({
    required super.id,
    required super.code,
    required super.inviteType,
    super.maxUses,
    super.expiresAt,
    required super.createdAt,
  });

  /// Создание модели из JSON
  factory InviteModel.fromJson(Map<String, dynamic> json) {
    return InviteModel(
      id: json['id'] as String,
      code: json['code'] as String,
      inviteType: InviteType.fromString(json['inviteType'] as String? ?? 'FAMILY'),
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
      inviteType: inviteType,
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
      'inviteType': inviteType.value,
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

/// Модель инвайта со ссылками (новый формат API)
class InviteWithLinksModel implements Model {
  final InviteModel invite;
  final InviteLinksModel links;

  const InviteWithLinksModel({
    required this.invite,
    required this.links,
  });

  /// Создание модели из JSON (новый формат: invite и links в одном объекте)
  factory InviteWithLinksModel.fromJson(Map<String, dynamic> json) {
    return InviteWithLinksModel(
      invite: InviteModel.fromJson(json),
      links: InviteLinksModel.fromJson(json['links'] as Map<String, dynamic>),
    );
  }

  /// Преобразование модели в доменную сущность
  InviteWithLinks toEntity() {
    return InviteWithLinks(
      invite: invite.toEntity(),
      links: links.toEntity(),
    );
  }

  /// Преобразование в CreateInviteResult для обратной совместимости
  CreateInviteResult toCreateInviteResult({bool hasBusiness = false}) {
    return CreateInviteResult(
      invite: invite.toEntity(),
      links: links.toEntity(),
      hasBusiness: hasBusiness,
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      ...invite.toJson(),
      'links': links.toJson(),
    };
  }
}

/// Модель списка инвайтов (новый формат API)
class InvitesListModel implements Model {
  final List<InviteWithLinksModel> invites;

  const InvitesListModel({
    required this.invites,
  });

  /// Создание модели из JSON
  factory InvitesListModel.fromJson(Map<String, dynamic> json) {
    final invitesList = json['invites'] as List<dynamic>;
    return InvitesListModel(
      invites: invitesList
          .map((item) => InviteWithLinksModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Преобразование модели в доменную сущность
  InvitesList toEntity() {
    return InvitesList(
      invites: invites.map((invite) => invite.toEntity()).toList(),
    );
  }

  /// Преобразование модели в JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'invites': invites.map((invite) => invite.toJson()).toList(),
    };
  }
}

/// Модель результата создания приглашения (старый формат, для обратной совместимости)
class CreateInviteResultModel extends CreateInviteResult implements Model {
  const CreateInviteResultModel({
    required super.invite,
    required super.links,
    super.isExisting,
    super.hasBusiness,
  });

  /// Создание модели из JSON
  factory CreateInviteResultModel.fromJson(Map<String, dynamic> json) {
    return CreateInviteResultModel(
      invite: InviteModel.fromJson(json['invite'] as Map<String, dynamic>),
      links: InviteLinksModel.fromJson(json['links'] as Map<String, dynamic>),
      isExisting: json['isExisting'] as bool? ?? false,
      hasBusiness: json['hasBusiness'] as bool? ?? false,
    );
  }

  /// Преобразование модели в доменную сущность
  CreateInviteResult toEntity() {
    return CreateInviteResult(
      invite: (invite as InviteModel).toEntity(),
      links: (links as InviteLinksModel).toEntity(),
      isExisting: isExisting,
      hasBusiness: hasBusiness,
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







