import '../../domain/entities/service.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/resource.dart';
import '../models/model.dart';
import 'employee_model.dart';
import 'resource_model.dart';

/// Модель назначения услуги
class ServiceAssignmentModel extends ServiceAssignment implements Model {
  const ServiceAssignmentModel({
    required super.id,
    required super.serviceId,
    super.employmentId,
    super.resourceId,
    super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.employee,
    super.resource,
  });

  factory ServiceAssignmentModel.fromJson(Map<String, dynamic> json) {
    // Парсинг employee
    Employee? employee;
    if (json['employment'] != null) {
      final employmentJson = json['employment'] as Map<String, dynamic>;
      if (employmentJson['user'] != null) {
        final userJson = employmentJson['user'] as Map<String, dynamic>;
        employee = EmployeeModel.fromJson({
          'id': userJson['id'] as String,
          'firstName': userJson['firstName'] as String? ?? '',
          'lastName': userJson['lastName'] as String? ?? '',
          'patronymic': userJson['patronymic'] as String?,
          'email': userJson['email'] as String?,
          'position': employmentJson['position'] as String?,
          'department': employmentJson['department']?['name'] as String?,
          'employmentId': employmentJson['id'] as String?,
        }).toEntity();
      }
    }

    // Парсинг resource
    Resource? resource;
    if (json['resource'] != null) {
      resource = ResourceModel.fromJson(json['resource'] as Map<String, dynamic>).toEntity();
    }

    return ServiceAssignmentModel(
      id: json['id'] as String,
      serviceId: json['serviceId'] as String,
      employmentId: json['employmentId'] as String?,
      resourceId: json['resourceId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      employee: employee,
      resource: resource,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      if (employmentId != null) 'employmentId': employmentId,
      if (resourceId != null) 'resourceId': resourceId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ServiceAssignment toEntity() {
    return ServiceAssignment(
      id: id,
      serviceId: serviceId,
      employmentId: employmentId,
      resourceId: resourceId,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      employee: employee,
      resource: resource,
    );
  }

  factory ServiceAssignmentModel.fromEntity(ServiceAssignment assignment) {
    return ServiceAssignmentModel(
      id: assignment.id,
      serviceId: assignment.serviceId,
      employmentId: assignment.employmentId,
      resourceId: assignment.resourceId,
      isActive: assignment.isActive,
      createdAt: assignment.createdAt,
      updatedAt: assignment.updatedAt,
      employee: assignment.employee,
      resource: assignment.resource,
    );
  }
}

