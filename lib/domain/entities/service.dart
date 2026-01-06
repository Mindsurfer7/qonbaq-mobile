import '../entities/entity.dart';
import 'employee.dart';
import 'resource.dart';
import 'user_profile.dart';

/// Доменная сущность услуги
class Service extends Entity {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final int duration; // Длительность в минутах
  final double? price;
  final String? currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ServiceAssignment>? assignments; // Назначения сотрудников/ресурсов
  final List<ProfileUser>? users; // Пользователи, участвующие в услуге

  const Service({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.duration,
    this.price,
    this.currency,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.assignments,
    this.users,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Service &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Service(id: $id, name: $name)';
}

/// Назначение сотрудника или ресурса на услугу
class ServiceAssignment extends Entity {
  final String id;
  final String serviceId;
  final String? employmentId; // ID сотрудника (employment)
  final String? resourceId; // ID ресурса
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Детальные данные (для детальной страницы)
  final Employee? employee; // Данные сотрудника
  final Resource? resource; // Данные ресурса

  const ServiceAssignment({
    required this.id,
    required this.serviceId,
    this.employmentId,
    this.resourceId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.employee,
    this.resource,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAssignment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ServiceAssignment(id: $id, serviceId: $serviceId)';
}

