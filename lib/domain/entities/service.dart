import '../entities/entity.dart';
import 'employee.dart';
import 'user_profile.dart';

/// Тип услуги
enum ServiceType {
  personBased('PERSON_BASED'),
  resourceBased('RESOURCE_BASED');

  final String value;
  const ServiceType(this.value);

  static ServiceType fromString(String value) {
    return ServiceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ServiceType.personBased,
    );
  }
}

/// Доменная сущность услуги
class Service extends Entity {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final ServiceType type; // Тип услуги: PERSON_BASED или RESOURCE_BASED
  final int? duration; // Длительность в минутах (обязательно для PERSON_BASED)
  final double? price; // Цена (обязательно для PERSON_BASED)
  final String? currency; // Валюта (по умолчанию KZT для PERSON_BASED)
  final int? capacity; // Вместимость (для RESOURCE_BASED)
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ServiceAssignment>? assignments; // Назначения сотрудников
  final List<ProfileUser>? users; // Пользователи, участвующие в услуге

  const Service({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.type,
    this.duration,
    this.price,
    this.currency,
    this.capacity,
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

/// Назначение сотрудника на услугу
class ServiceAssignment extends Entity {
  final String id;
  final String serviceId;
  final String? employmentId; // ID сотрудника (employment) - обязательно для PERSON_BASED услуг
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Детальные данные (для детальной страницы)
  final Employee? employee; // Данные сотрудника

  const ServiceAssignment({
    required this.id,
    required this.serviceId,
    this.employmentId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.employee,
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

