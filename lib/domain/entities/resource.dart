import '../entities/entity.dart';

/// Доменная сущность ресурса
class Resource extends Entity {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Resource({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resource &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Resource(id: $id, name: $name)';
}

