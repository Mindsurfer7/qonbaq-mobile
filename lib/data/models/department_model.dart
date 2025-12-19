import '../../domain/entities/department.dart';
import '../models/model.dart';

/// Модель подразделения
class DepartmentModel extends Department implements Model {
  const DepartmentModel({
    required super.id,
    required super.name,
    super.description,
    required super.businessId,
    super.parentId,
    super.managerId,
    super.manager,
    super.employeesCount,
    super.childrenCount,
    super.business,
    super.parent,
    super.children,
    super.employees,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    // Парсим менеджера
    DepartmentManager? manager;
    if (json['manager'] != null) {
      final managerJson = json['manager'] as Map<String, dynamic>;
      manager = DepartmentManager(
        id: managerJson['id'] as String,
        email: managerJson['email'] as String,
        username: managerJson['username'] as String,
        firstName: managerJson['firstName'] as String?,
        lastName: managerJson['lastName'] as String?,
        patronymic: managerJson['patronymic'] as String?,
      );
    }

    // Парсим бизнес
    BusinessInfo? business;
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = BusinessInfo(
        id: businessJson['id'] as String,
        name: businessJson['name'] as String,
      );
    }

    // Парсим родительское подразделение
    DepartmentInfo? parent;
    if (json['parent'] != null) {
      final parentJson = json['parent'] as Map<String, dynamic>;
      parent = DepartmentInfo(
        id: parentJson['id'] as String,
        name: parentJson['name'] as String,
        description: parentJson['description'] as String?,
      );
    }

    // Парсим дочерние подразделения
    List<DepartmentInfo> children = [];
    if (json['children'] != null) {
      final childrenList = json['children'] as List<dynamic>;
      children = childrenList
          .map((item) {
            final childJson = item as Map<String, dynamic>;
            return DepartmentInfo(
              id: childJson['id'] as String,
              name: childJson['name'] as String,
              description: childJson['description'] as String?,
            );
          })
          .toList();
    }

    // Парсим сотрудников
    List<DepartmentEmployee> employees = [];
    if (json['employees'] != null) {
      final employeesList = json['employees'] as List<dynamic>;
      employees = employeesList
          .map((item) {
            final empJson = item as Map<String, dynamic>;
            return DepartmentEmployee(
              id: empJson['id'] as String,
              email: empJson['email'] as String,
              username: empJson['username'] as String,
              firstName: empJson['firstName'] as String?,
              lastName: empJson['lastName'] as String?,
              patronymic: empJson['patronymic'] as String?,
              phone: empJson['phone'] as String?,
              position: empJson['position'] as String?,
              orgPosition: empJson['orgPosition'] as String?,
            );
          })
          .toList();
    }

    return DepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      businessId: json['businessId'] as String,
      parentId: json['parentId'] as String?,
      managerId: manager?.id ?? json['managerId'] as String?,
      manager: manager,
      employeesCount: json['employeesCount'] as int?,
      childrenCount: json['childrenCount'] as int?,
      business: business,
      parent: parent,
      children: children,
      employees: employees,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'businessId': businessId,
      if (parentId != null) 'parentId': parentId,
      if (managerId != null) 'managerId': managerId,
      if (manager != null)
        'manager': {
          'id': manager!.id,
          'email': manager!.email,
          'username': manager!.username,
          if (manager!.firstName != null) 'firstName': manager!.firstName,
          if (manager!.lastName != null) 'lastName': manager!.lastName,
          if (manager!.patronymic != null) 'patronymic': manager!.patronymic,
        },
      if (employeesCount != null) 'employeesCount': employeesCount,
      if (childrenCount != null) 'childrenCount': childrenCount,
      if (business != null)
        'business': {
          'id': business!.id,
          'name': business!.name,
        },
      if (parent != null)
        'parent': {
          'id': parent!.id,
          'name': parent!.name,
          if (parent!.description != null) 'description': parent!.description,
        },
      if (children.isNotEmpty)
        'children': children.map((child) => {
              'id': child.id,
              'name': child.name,
              if (child.description != null) 'description': child.description,
            }).toList(),
      if (employees.isNotEmpty)
        'employees': employees.map((emp) => {
              'id': emp.id,
              'email': emp.email,
              'username': emp.username,
              if (emp.firstName != null) 'firstName': emp.firstName,
              if (emp.lastName != null) 'lastName': emp.lastName,
              if (emp.patronymic != null) 'patronymic': emp.patronymic,
              if (emp.phone != null) 'phone': emp.phone,
              if (emp.position != null) 'position': emp.position,
              if (emp.orgPosition != null) 'orgPosition': emp.orgPosition,
            }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// JSON для создания департамента (без id, createdAt, updatedAt)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'businessId': businessId,
      if (parentId != null) 'parentId': parentId,
      if (managerId != null) 'managerId': managerId,
    };
  }

  /// JSON для обновления департамента
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      'description': description, // может быть null
      if (managerId != null) 'managerId': managerId,
    };
  }

  Department toEntity() {
    return Department(
      id: id,
      name: name,
      description: description,
      businessId: businessId,
      parentId: parentId,
      managerId: managerId,
      manager: manager,
      employeesCount: employeesCount,
      childrenCount: childrenCount,
      business: business,
      parent: parent,
      children: children,
      employees: employees,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory DepartmentModel.fromEntity(Department department) {
    return DepartmentModel(
      id: department.id,
      name: department.name,
      description: department.description,
      businessId: department.businessId,
      parentId: department.parentId,
      managerId: department.managerId,
      manager: department.manager,
      employeesCount: department.employeesCount,
      childrenCount: department.childrenCount,
      business: department.business,
      parent: department.parent,
      children: department.children,
      employees: department.employees,
      createdAt: department.createdAt,
      updatedAt: department.updatedAt,
    );
  }
}

