import '../../domain/entities/project.dart';
import '../models/model.dart';

/// Модель проекта
class ProjectModel extends Project implements Model {
  const ProjectModel({
    required super.id,
    required super.name,
    super.description,
    required super.businessId,
    super.business,
    super.city,
    super.country,
    super.address,
    super.isActive,
    super.accountsCount,
    super.transactionsCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    // Парсим бизнес
    ProjectBusinessInfo? business;
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = ProjectBusinessInfo(
        id: businessJson['id'] as String? ?? '',
        name: businessJson['name'] as String? ?? '',
      );
    }

    // Парсим основные поля
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final businessId = json['businessId'] as String? ?? '';

    // Парсим даты с безопасной обработкой
    DateTime createdAt;
    DateTime updatedAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now();
      updatedAt = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
      updatedAt = DateTime.now();
    }

    return ProjectModel(
      id: id,
      name: name,
      description: json['description'] as String?,
      businessId: businessId,
      business: business,
      city: json['city'] as String?,
      country: json['country'] as String?,
      address: json['address'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      accountsCount: json['accountsCount'] as int?,
      transactionsCount: json['transactionsCount'] as int?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'businessId': businessId,
      if (business != null)
        'business': {
          'id': business!.id,
          'name': business!.name,
        },
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (address != null) 'address': address,
      'isActive': isActive,
      if (accountsCount != null) 'accountsCount': accountsCount,
      if (transactionsCount != null) 'transactionsCount': transactionsCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON для создания проекта (без id, createdAt, updatedAt)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'businessId': businessId,
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (address != null) 'address': address,
    };
  }

  /// JSON для обновления проекта
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      'description': description, // может быть null
      if (city != null) 'city': city,
      if (country != null) 'country': country,
      if (address != null) 'address': address,
      'isActive': isActive,
    };
  }

  Project toEntity() {
    return Project(
      id: id,
      name: name,
      description: description,
      businessId: businessId,
      business: business,
      city: city,
      country: country,
      address: address,
      isActive: isActive,
      accountsCount: accountsCount,
      transactionsCount: transactionsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ProjectModel.fromEntity(Project project) {
    return ProjectModel(
      id: project.id,
      name: project.name,
      description: project.description,
      businessId: project.businessId,
      business: project.business,
      city: project.city,
      country: project.country,
      address: project.address,
      isActive: project.isActive,
      accountsCount: project.accountsCount,
      transactionsCount: project.transactionsCount,
      createdAt: project.createdAt,
      updatedAt: project.updatedAt,
    );
  }
}

