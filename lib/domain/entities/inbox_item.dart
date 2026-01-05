import '../entities/entity.dart';
import 'business.dart';
import 'user_profile.dart';

/// Доменная сущность Inbox Item (элемент "Не забыть выполнить")
class InboxItem extends Entity {
  final String id;
  final String userId;
  final String businessId;
  final String? title;
  final String? description;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Детальные данные (для детальной страницы)
  final ProfileUser? user;
  final Business? business;

  const InboxItem({
    required this.id,
    required this.userId,
    required this.businessId,
    this.title,
    this.description,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.business,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InboxItem(id: $id, title: ${title ?? "без названия"})';
}

