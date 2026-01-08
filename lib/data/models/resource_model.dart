import '../../domain/entities/resource.dart';
import '../models/model.dart';

/// Модель ресурса
class ResourceModel extends Resource implements Model {
  const ResourceModel({
    required super.id,
    required super.businessId,
    required super.name,
    super.description,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ResourceModel.fromJson(Map<String, dynamic> json) {
    return ResourceModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания ресурса
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
    };
  }

  /// Преобразование в JSON для обновления ресурса
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      'isActive': isActive,
    };
  }

  Resource toEntity() {
    return Resource(
      id: id,
      businessId: businessId,
      name: name,
      description: description,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ResourceModel.fromEntity(Resource resource) {
    return ResourceModel(
      id: resource.id,
      businessId: resource.businessId,
      name: resource.name,
      description: resource.description,
      isActive: resource.isActive,
      createdAt: resource.createdAt,
      updatedAt: resource.updatedAt,
    );
  }
}


