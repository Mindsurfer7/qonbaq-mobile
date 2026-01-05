import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../models/model.dart';
import 'business_model.dart';

/// Модель Inbox Item
class InboxItemModel extends InboxItem implements Model {
  const InboxItemModel({
    required super.id,
    required super.userId,
    required super.businessId,
    super.title,
    super.description,
    super.isArchived,
    super.category,
    required super.createdAt,
    required super.updatedAt,
    super.user,
    super.business,
  });

  factory InboxItemModel.fromJson(Map<String, dynamic> json) {
    ProfileUser? user;
    Business? business;

    // Парсим вложенный объект user, если есть
    if (json['user'] != null) {
      final userJson = json['user'] as Map<String, dynamic>;
      user = ProfileUser(
        id: userJson['id'] as String,
        email: userJson['email'] as String? ?? '',
        firstName: userJson['firstName'] as String?,
        lastName: userJson['lastName'] as String?,
        phone: userJson['phone'] as String?,
      );
    }

    // Парсим вложенный объект business, если есть
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = BusinessModel.fromJson(businessJson).toEntity();
    }

    // Парсим category
    InboxItemCategory? category;
    if (json['category'] != null) {
      category = InboxItemCategoryUtils.fromString(json['category'] as String);
    }

    return InboxItemModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessId: json['businessId'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      category: category,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      user: user,
      business: business,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessId': businessId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'isArchived': isArchived,
      if (category != null) 'category': category!.toApiString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (user != null) 'user': {
        'id': user!.id,
        'email': user!.email,
        if (user!.firstName != null) 'firstName': user!.firstName,
        if (user!.lastName != null) 'lastName': user!.lastName,
        if (user!.phone != null) 'phone': user!.phone,
      },
      if (business != null) 'business': BusinessModel.fromEntity(business!).toJson(),
    };
  }

  /// Преобразование в JSON для создания/обновления
  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (category != null) 'category': category!.toApiString(),
    };
  }

  /// Преобразование в JSON для обновления
  Map<String, dynamic> toUpdateJson() {
    return {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      'isArchived': isArchived,
      if (category != null) 'category': category!.toApiString(),
    };
  }

  InboxItem toEntity() {
    return InboxItem(
      id: id,
      userId: userId,
      businessId: businessId,
      title: title,
      description: description,
      isArchived: isArchived,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      user: user,
      business: business,
    );
  }

  factory InboxItemModel.fromEntity(InboxItem inboxItem) {
    return InboxItemModel(
      id: inboxItem.id,
      userId: inboxItem.userId,
      businessId: inboxItem.businessId,
      title: inboxItem.title,
      description: inboxItem.description,
      isArchived: inboxItem.isArchived,
      category: inboxItem.category,
      createdAt: inboxItem.createdAt,
      updatedAt: inboxItem.updatedAt,
      user: inboxItem.user,
      business: inboxItem.business,
    );
  }
}

