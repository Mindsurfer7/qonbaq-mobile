import '../entities/entity.dart';

/// Информация о бизнесе проекта
class ProjectBusinessInfo extends Entity {
  final String id;
  final String name;

  const ProjectBusinessInfo({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBusinessInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Доменная сущность проекта
class Project extends Entity {
  final String id;
  final String name;
  final String? description;
  final String businessId;
  final ProjectBusinessInfo? business;
  final String? city;
  final String? country;
  final String? address;
  final bool isActive;
  final int? accountsCount;
  final int? transactionsCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.businessId,
    this.business,
    this.city,
    this.country,
    this.address,
    this.isActive = true,
    this.accountsCount,
    this.transactionsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Project(id: $id, name: $name)';
}



