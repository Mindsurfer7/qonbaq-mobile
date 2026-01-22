import 'entity.dart';

/// Тип приглашения
enum InviteType {
  family,
  business;

  String get value => name.toUpperCase();
  
  static InviteType fromString(String value) {
    return value.toUpperCase() == 'BUSINESS' ? InviteType.business : InviteType.family;
  }
}

/// Доменная сущность приглашения
class Invite extends Entity {
  final String id;
  final String code;
  final InviteType inviteType;
  final int? maxUses;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Invite({
    required this.id,
    required this.code,
    required this.inviteType,
    this.maxUses,
    this.expiresAt,
    required this.createdAt,
  });
}

/// Ссылки для приглашения
class InviteLinks extends Entity {
  final String web;
  final String deepLink;

  const InviteLinks({
    required this.web,
    required this.deepLink,
  });
}

/// Результат создания приглашения
class CreateInviteResult extends Entity {
  final Invite invite;
  final InviteLinks links;
  final bool isExisting;
  final bool hasBusiness;

  const CreateInviteResult({
    required this.invite,
    required this.links,
    this.isExisting = false,
    this.hasBusiness = false,
  });
}

/// Инвайт со ссылками
class InviteWithLinks extends Entity {
  final Invite invite;
  final InviteLinks links;

  const InviteWithLinks({
    required this.invite,
    required this.links,
  });
}

/// Список инвайтов
class InvitesList extends Entity {
  final List<InviteWithLinks> invites;

  const InvitesList({
    required this.invites,
  });

  /// Получить инвайт по типу
  InviteWithLinks? getInviteByType(InviteType type) {
    try {
      return invites.firstWhere(
        (invite) => invite.invite.inviteType == type,
      );
    } catch (e) {
      return null;
    }
  }

  /// Проверка наличия бизнеса (если есть BUSINESS инвайт)
  bool get hasBusiness => getInviteByType(InviteType.business) != null;
}







