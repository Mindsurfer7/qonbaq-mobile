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
      
      if (typeStr == 'family') {
        type = BusinessType.family;
      } else if (typeStr == 'business') {
        type = BusinessType.business;
      }
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
    );
  }
}


