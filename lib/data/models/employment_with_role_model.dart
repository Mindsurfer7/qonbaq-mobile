import '../../domain/entities/employment_with_role.dart';
import '../models/model.dart';

/// Модель назначения департамента
class DepartmentAssignmentModel implements Model {
  final String departmentId;
  final String departmentName;
  final bool becameManager;

  const DepartmentAssignmentModel({
    required this.departmentId,
    required this.departmentName,
    required this.becameManager,
  });

  factory DepartmentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentAssignmentModel(
      departmentId: json['departmentId'] as String,
      departmentName: json['departmentName'] as String,
      becameManager: json['becameManager'] as bool,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentName': departmentName,
      'becameManager': becameManager,
    };
  }

  DepartmentAssignment toEntity() {
    return DepartmentAssignment(
      departmentId: departmentId,
      departmentName: departmentName,
      becameManager: becameManager,
    );
  }

  factory DepartmentAssignmentModel.fromEntity(DepartmentAssignment assignment) {
    return DepartmentAssignmentModel(
      departmentId: assignment.departmentId,
      departmentName: assignment.departmentName,
      becameManager: assignment.becameManager,
    );
  }
}

/// Модель трудоустройства с ролью
class EmploymentWithRoleModel implements Model {
  final String id;
  final String userId;
  final String businessId;
  final String? position;
  final String? orgPosition;
  final String? roleCode;
  final EmploymentUserModel user;
  final EmploymentBusinessModel business;
  final EmploymentRoleModel? role;
  final DepartmentAssignmentModel? departmentAssignment;

  const EmploymentWithRoleModel({
    required this.id,
    required this.userId,
    required this.businessId,
    this.position,
    this.orgPosition,
    this.roleCode,
    required this.user,
    required this.business,
    this.role,
    this.departmentAssignment,
  });

  factory EmploymentWithRoleModel.fromJson(Map<String, dynamic> json) {
    return EmploymentWithRoleModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      businessId: json['businessId'] as String,
      position: json['position'] as String?,
      orgPosition: json['orgPosition'] as String?,
      roleCode: json['roleCode'] as String?,
      user: EmploymentUserModel.fromJson(json['user'] as Map<String, dynamic>),
      business: EmploymentBusinessModel.fromJson(json['business'] as Map<String, dynamic>),
      role: json['role'] != null
          ? EmploymentRoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
      departmentAssignment: json['departmentAssignment'] != null
          ? DepartmentAssignmentModel.fromJson(json['departmentAssignment'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessId': businessId,
      if (position != null) 'position': position,
      if (orgPosition != null) 'orgPosition': orgPosition,
      if (roleCode != null) 'roleCode': roleCode,
      'user': user.toJson(),
      'business': business.toJson(),
      if (role != null) 'role': role!.toJson(),
      if (departmentAssignment != null) 'departmentAssignment': departmentAssignment!.toJson(),
    };
  }

  EmploymentWithRole toEntity() {
    return EmploymentWithRole(
      id: id,
      userId: userId,
      businessId: businessId,
      position: position,
      orgPosition: orgPosition,
      roleCode: roleCode,
      user: user.toEntity(),
      business: business.toEntity(),
      role: role?.toEntity(),
      departmentAssignment: departmentAssignment?.toEntity(),
    );
  }

  factory EmploymentWithRoleModel.fromEntity(EmploymentWithRole employment) {
    return EmploymentWithRoleModel(
      id: employment.id,
      userId: employment.userId,
      businessId: employment.businessId,
      position: employment.position,
      orgPosition: employment.orgPosition,
      roleCode: employment.roleCode,
      user: EmploymentUserModel.fromEntity(employment.user),
      business: EmploymentBusinessModel.fromEntity(employment.business),
      role: employment.role != null
          ? EmploymentRoleModel.fromEntity(employment.role!)
          : null,
      departmentAssignment: employment.departmentAssignment != null
          ? DepartmentAssignmentModel(
              departmentId: employment.departmentAssignment!.departmentId,
              departmentName: employment.departmentAssignment!.departmentName,
              becameManager: employment.departmentAssignment!.becameManager,
            )
          : null,
    );
  }
}

/// Модель пользователя в трудоустройстве
class EmploymentUserModel implements Model {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;

  const EmploymentUserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
  });

  factory EmploymentUserModel.fromJson(Map<String, dynamic> json) {
    return EmploymentUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (patronymic != null) 'patronymic': patronymic,
    };
  }

  EmploymentUser toEntity() {
    return EmploymentUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      patronymic: patronymic,
    );
  }

  factory EmploymentUserModel.fromEntity(EmploymentUser user) {
    return EmploymentUserModel(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      patronymic: user.patronymic,
    );
  }
}

/// Модель бизнеса в трудоустройстве
class EmploymentBusinessModel implements Model {
  final String id;
  final String name;

  const EmploymentBusinessModel({
    required this.id,
    required this.name,
  });

  factory EmploymentBusinessModel.fromJson(Map<String, dynamic> json) {
    return EmploymentBusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  EmploymentBusiness toEntity() {
    return EmploymentBusiness(
      id: id,
      name: name,
    );
  }

  factory EmploymentBusinessModel.fromEntity(EmploymentBusiness business) {
    return EmploymentBusinessModel(
      id: business.id,
      name: business.name,
    );
  }
}

/// Модель роли в трудоустройстве
class EmploymentRoleModel implements Model {
  final String code;
  final String name;

  const EmploymentRoleModel({
    required this.code,
    required this.name,
  });

  factory EmploymentRoleModel.fromJson(Map<String, dynamic> json) {
    return EmploymentRoleModel(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  EmploymentRole toEntity() {
    return EmploymentRole(
      code: code,
      name: name,
    );
  }

  factory EmploymentRoleModel.fromEntity(EmploymentRole role) {
    return EmploymentRoleModel(
      code: role.code,
      name: role.name,
    );
  }
}