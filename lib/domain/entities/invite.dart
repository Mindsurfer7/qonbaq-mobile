import 'entity.dart';

/// Доменная сущность приглашения
class Invite extends Entity {
  final String id;
  final String code;
  final int? maxUses;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const Invite({
    required this.id,
    required this.code,
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

  const CreateInviteResult({
    required this.invite,
    required this.links,
  });
}







