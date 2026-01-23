import '../entities/entity.dart';

/// Тип workspace
enum BusinessType {
  family,
  business,
}

/// Доменная сущность компании
class Business extends Entity {
  final String id;
  final String name;
  final String? description;
  final String? position;
  final String? orgPosition;
  final String? department;
  final DateTime? hireDate;
  final DateTime? createdAt;
  final BusinessType? type;
  final bool autoAssignDepartments; // Автоматическое распределение сотрудников по департаментам

  const Business({
    required this.id,
    required this.name,
    this.description,
    this.position,
    this.orgPosition,
    this.department,
    this.hireDate,
    this.createdAt,
    this.type,
    this.autoAssignDepartments = true, // По умолчанию true
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Business &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;

  @override
  String toString() => 'Business(id: $id, name: $name)';
}


