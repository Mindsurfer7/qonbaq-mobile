import 'package:flutter/foundation.dart';
import '../../domain/entities/business.dart';
import '../models/model.dart';

/// Модель компании
class BusinessModel extends Business implements Model {
  const BusinessModel({
    required super.id,
    required super.name,
    super.description,
    super.position,
    super.orgPosition,
    super.department,
    super.hireDate,
    super.createdAt,
    super.type,
    super.autoAssignDepartments = true,
    super.slug,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    // Парсим тип бизнеса
    BusinessType? type;
    if (json['type'] != null) {
      final typeValue = json['type'];
      String typeStr;
      if (typeValue is String) {
        typeStr = typeValue.toLowerCase();
      } else {
        typeStr = typeValue.toString().toLowerCase();
      }
      
      debugPrint('🔍 BusinessModel.fromJson: парсим тип "$typeStr" из значения "$typeValue"');
      
      if (typeStr == 'family') {
        type = BusinessType.family;
      } else if (typeStr == 'business') {
        type = BusinessType.business;
      } else {
        debugPrint('⚠️ BusinessModel.fromJson: неизвестный тип "$typeStr", оставляем null');
      }
    } else {
      debugPrint('⚠️ BusinessModel.fromJson: поле "type" отсутствует в JSON для бизнеса "${json['name']}"');
    }

    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      position: json['position'] as String?,
      orgPosition: json['orgPosition'] as String?,
      department: json['department'] as String?,
      hireDate:
          json['hireDate'] != null
              ? DateTime.parse(json['hireDate'] as String)
              : null,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : null,
      type: type,
      autoAssignDepartments: json['autoAssignDepartments'] as bool? ?? true,
      slug: json['slug'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (position != null) 'position': position,
      if (orgPosition != null) 'orgPosition': orgPosition,
      if (department != null) 'department': department,
      if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (type != null) 'type': type == BusinessType.family ? 'Family' : 'Business',
      'autoAssignDepartments': autoAssignDepartments,
      if (slug != null) 'slug': slug,
    };
  }

  /// JSON для создания бизнеса (без id и других полей, генерируемых на сервере)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'type': type == BusinessType.family ? 'FAMILY' : 'BUSINESS',
    };
  }

  Business toEntity() {
    return Business(
      id: id,
      name: name,
      description: description,
      position: position,
      orgPosition: orgPosition,
      department: department,
      hireDate: hireDate,
      createdAt: createdAt,
      type: type,
      autoAssignDepartments: autoAssignDepartments,
      slug: slug,
    );
  }

  factory BusinessModel.fromEntity(Business business) {
    return BusinessModel(
      id: business.id,
      name: business.name,
      description: business.description,
      position: business.position,
      orgPosition: business.orgPosition,
      department: business.department,
      hireDate: business.hireDate,
      createdAt: business.createdAt,
      type: business.type,
      autoAssignDepartments: business.autoAssignDepartments,
      slug: business.slug,
    );
  }

  /// JSON для обновления бизнеса
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (description != null) 'description': description,
      'autoAssignDepartments': autoAssignDepartments,
      'slug': slug, // slug может быть null для удаления
    };
  }
}


