import '../entities/entity.dart';
import 'business.dart';
import 'user_profile.dart';

/// Категории для Inbox Item
enum InboxItemCategory {
  workMiscellaneous, // Разное по работе
  personalMiscellaneous, // Разное по своим делам
  readLater, // Почитать потом
  watchVideoLater, // Посмотреть видео
  doThisYear, // Сделать в этом году
  doIn510Years, // Сделать в ближайшие 5-10 лет
}

/// Расширение для InboxItemCategory
extension InboxItemCategoryExtension on InboxItemCategory {
  /// Преобразование в строку (для API)
  String toApiString() {
    switch (this) {
      case InboxItemCategory.workMiscellaneous:
        return 'WORK_MISCELLANEOUS';
      case InboxItemCategory.personalMiscellaneous:
        return 'PERSONAL_MISCELLANEOUS';
      case InboxItemCategory.readLater:
        return 'READ_LATER';
      case InboxItemCategory.watchVideoLater:
        return 'WATCH_VIDEO_LATER';
      case InboxItemCategory.doThisYear:
        return 'DO_THIS_YEAR';
      case InboxItemCategory.doIn510Years:
        return 'DO_IN_5_10_YEARS';
    }
  }

  /// Получить название категории на русском
  String get displayName {
    switch (this) {
      case InboxItemCategory.workMiscellaneous:
        return 'Разное по работе';
      case InboxItemCategory.personalMiscellaneous:
        return 'Разное по своим делам';
      case InboxItemCategory.readLater:
        return 'Почитать потом';
      case InboxItemCategory.watchVideoLater:
        return 'Посмотреть видео';
      case InboxItemCategory.doThisYear:
        return 'Сделать в этом году';
      case InboxItemCategory.doIn510Years:
        return 'Сделать в ближайшие 5-10 лет';
    }
  }
}

/// Утилиты для работы с InboxItemCategory
class InboxItemCategoryUtils {
  /// Преобразование из строки (из API)
  static InboxItemCategory? fromString(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'WORK_MISCELLANEOUS':
        return InboxItemCategory.workMiscellaneous;
      case 'PERSONAL_MISCELLANEOUS':
        return InboxItemCategory.personalMiscellaneous;
      case 'READ_LATER':
        return InboxItemCategory.readLater;
      case 'WATCH_VIDEO_LATER':
        return InboxItemCategory.watchVideoLater;
      case 'DO_THIS_YEAR':
        return InboxItemCategory.doThisYear;
      case 'DO_IN_5_10_YEARS':
        return InboxItemCategory.doIn510Years;
      default:
        return null;
    }
  }
}

/// Доменная сущность Inbox Item (элемент "Не забыть выполнить")
class InboxItem extends Entity {
  final String id;
  final String userId;
  final String businessId;
  final String? title;
  final String? description;
  final bool isArchived;
  final InboxItemCategory? category;
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
    this.category,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.business,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InboxItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'InboxItem(id: $id, title: ${title ?? "без названия"})';
}
