import '../entities/entity.dart';

/// Модель менеджера подразделения
class DepartmentManager extends Entity {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? patronymic;

  const DepartmentManager({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.patronymic,
  });

  String get fullName {
    final parts = <String>[];
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (patronymic != null && patronymic!.isNotEmpty) parts.add(patronymic!);
    return parts.isEmpty ? username : parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentManager &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Краткая информация о подразделении
class DepartmentInfo extends Entity {
  final String id;
  final String name;
  final String? description;

  const DepartmentInfo({
    required this.id,
    required this.name,
    this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Информация о бизнесе
class BusinessInfo extends Entity {
  final String id;
  final String name;

  const BusinessInfo({
    required this.id,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessInfo &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Информация о сотруднике подразделения
class DepartmentEmployee extends Entity {
  final String id;
  final String email;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? patronymic;
  final String? phone;
  final String? position;
  final String? orgPosition;

  const DepartmentEmployee({
    required this.id,
    required this.email,
    required this.username,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.phone,
    this.position,
    this.orgPosition,
  });

  String get fullName {
    final parts = <String>[];
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (patronymic != null && patronymic!.isNotEmpty) parts.add(patronymic!);
    return parts.isEmpty ? username : parts.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentEmployee &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Доменная сущность подразделения
class Department extends Entity {
  final String id;
  final String name;
  final String? description;
  final String businessId;
  final String? parentId;
  final String? managerId;
  final DepartmentManager? manager;
  final int? employeesCount;
  final int? childrenCount;
  final BusinessInfo? business;
  final DepartmentInfo? parent;
  final List<DepartmentInfo> children;
  final List<DepartmentEmployee> employees;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Department({
    required this.id,
    required this.name,
    this.description,
    required this.businessId,
    this.parentId,
    this.managerId,
    this.manager,
    this.employeesCount,
    this.childrenCount,
    this.business,
    this.parent,
    this.children = const [],
    this.employees = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Department &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Department(id: $id, name: $name)';
}

