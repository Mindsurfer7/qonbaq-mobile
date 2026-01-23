import '../entities/entity.dart';

/// Информация о назначении департамента при назначении роли
class DepartmentAssignment extends Entity {
  final String departmentId;
  final String departmentName;
  final bool becameManager; // Стал ли сотрудник менеджером департамента

  const DepartmentAssignment({
    required this.departmentId,
    required this.departmentName,
    required this.becameManager,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DepartmentAssignment &&
          runtimeType == other.runtimeType &&
          departmentId == other.departmentId;

  @override
  int get hashCode => departmentId.hashCode;
}

/// Доменная сущность трудоустройства с ролью
class EmploymentWithRole extends Entity {
  final String id;
  final String userId;
  final String businessId;
  final String? position;
  final String? orgPosition;
  final String? roleCode;
  final EmploymentUser user;
  final EmploymentBusiness business;
  final EmploymentRole? role;
  final DepartmentAssignment? departmentAssignment; // Информация о назначении департамента

  const EmploymentWithRole({
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

  /// Полное имя сотрудника
  String get fullName {
    final parts = [user.lastName, user.firstName];
    if (user.patronymic != null && user.patronymic!.isNotEmpty) {
      parts.add(user.patronymic!);
    }
    return parts.join(' ');
  }

  /// Краткое имя сотрудника (Фамилия И.О.)
  String get shortName {
    final lastNamePart = user.lastName;
    final firstNamePart = user.firstName?.isNotEmpty == true ? user.firstName![0] : '';
    final patronymicPart =
        user.patronymic != null && user.patronymic!.isNotEmpty ? user.patronymic![0] : '';
    return '$lastNamePart $firstNamePart.$patronymicPart.'.trim();
  }

  /// Название роли
  String? get roleName => role?.name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmploymentWithRole && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EmploymentWithRole(id: $id, user: $fullName, role: $roleCode)';
}

/// Пользователь в трудоустройстве
class EmploymentUser extends Entity {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;

  const EmploymentUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
  });
}

/// Бизнес в трудоустройстве
class EmploymentBusiness extends Entity {
  final String id;
  final String name;

  const EmploymentBusiness({
    required this.id,
    required this.name,
  });
}

/// Роль в трудоустройстве
class EmploymentRole extends Entity {
  final String code;
  final String name;

  const EmploymentRole({
    required this.code,
    required this.name,
  });
}