import '../entities/entity.dart';
import 'business.dart';
import 'employment_enums.dart';

/// Доменная сущность профиля пользователя
class UserProfile extends Entity {
  final ProfileUser user;
  final Business business;
  final Employment employment;
  final EmployeeData employeeData;
  final OrgStructure orgStructure;
  final InterchangeableEmployee? interchangeableEmployee;
  final List<HrDocument> hrDocuments;

  const UserProfile({
    required this.user,
    required this.business,
    required this.employment,
    required this.employeeData,
    required this.orgStructure,
    this.interchangeableEmployee,
    required this.hrDocuments,
  });
}

/// Пользователь в профиле
class ProfileUser extends Entity {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;
  final String? phone;

  const ProfileUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.phone,
  });
}

/// Трудоустройство
class Employment extends Entity {
  final String id;
  final String? position;
  final String? positionType;
  final String? orgPosition;
  final String? department;
  final DateTime? hireDate;
  final String? workPhone;
  final String? workExperience;
  final String? accountability;
  final String? personnelNumber;
  final bool isActive;

  const Employment({
    required this.id,
    this.position,
    this.positionType,
    this.orgPosition,
    this.department,
    this.hireDate,
    this.workPhone,
    this.workExperience,
    this.accountability,
    this.personnelNumber,
    required this.isActive,
  });

  /// Получить enum организационной позиции
  OrgPositionCode? get orgPositionCode =>
      OrgPositionCodeExtension.fromCode(orgPosition);
}

/// Данные сотрудника
class EmployeeData extends Entity {
  final String? photo;
  final String? lastName;
  final String? firstName;
  final String? patronymic;
  final String? department;
  final String? position;
  final DateTime? hireDate;
  final String? positionType;
  final String? email;
  final String? workPhone;
  final String? workExperience;
  final String? accountability;
  final String? personnelNumber;

  const EmployeeData({
    this.photo,
    this.lastName,
    this.firstName,
    this.patronymic,
    this.department,
    this.position,
    this.hireDate,
    this.positionType,
    this.email,
    this.workPhone,
    this.workExperience,
    this.accountability,
    this.personnelNumber,
  });
}

/// Организационная структура
class OrgStructure extends Entity {
  final bool isGeneralDirector;
  final bool isProjectManager;
  final bool isDepartmentHead;
  final bool isEmployee;
  final String? currentPosition;

  const OrgStructure({
    required this.isGeneralDirector,
    required this.isProjectManager,
    required this.isDepartmentHead,
    required this.isEmployee,
    this.currentPosition,
  });
}

/// Взаимозаменяемый сотрудник
class InterchangeableEmployee extends Entity {
  final String id;
  final String fullName;

  const InterchangeableEmployee({required this.id, required this.fullName});
}

/// Кадровый документ
class HrDocument extends Entity {
  final String id;
  final String type;
  final String title;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HrDocument({
    required this.id,
    required this.type,
    required this.title,
    this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
  });
}


