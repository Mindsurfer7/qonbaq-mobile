import '../../domain/entities/user_profile.dart';
import '../models/model.dart';
import 'business_model.dart';
import 'workday_model.dart';

/// Модель профиля пользователя
class UserProfileModel implements Model {
  final ProfileUserModel user;
  final BusinessModel business;
  final EmploymentModel employment;
  final EmployeeDataModel employeeData;
  final OrgStructureModel orgStructure;
  final InterchangeableEmployeeModel? interchangeableEmployee;
  final List<HrDocumentModel> hrDocuments;
  final WorkDayModel? workDay;

  const UserProfileModel({
    required this.user,
    required this.business,
    required this.employment,
    required this.employeeData,
    required this.orgStructure,
    this.interchangeableEmployee,
    required this.hrDocuments,
    this.workDay,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final businessId = json['business'] != null
        ? (json['business'] as Map<String, dynamic>)['id'] as String?
        : null;
    
    return UserProfileModel(
      user: ProfileUserModel.fromJson(json['user'] as Map<String, dynamic>),
      business: BusinessModel.fromJson(
        json['business'] as Map<String, dynamic>,
      ),
      employment: EmploymentModel.fromJson(
        json['employment'] as Map<String, dynamic>,
      ),
      employeeData: EmployeeDataModel.fromJson(
        json['employeeData'] as Map<String, dynamic>,
      ),
      orgStructure: OrgStructureModel.fromJson(
        json['orgStructure'] as Map<String, dynamic>,
      ),
      interchangeableEmployee:
          json['interchangeableEmployee'] != null
              ? InterchangeableEmployeeModel.fromJson(
                json['interchangeableEmployee'] as Map<String, dynamic>,
              )
              : null,
      hrDocuments:
          (json['hrDocuments'] as List<dynamic>?)
              ?.map(
                (item) =>
                    HrDocumentModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      workDay: json['workDay'] != null
          ? () {
              final workDayJson = json['workDay'] as Map<String, dynamic>;
              // Добавляем businessId, если его нет
              if (businessId != null && !workDayJson.containsKey('businessId')) {
                workDayJson['businessId'] = businessId;
              }
              // Добавляем date, если его нет (используем сегодняшнюю дату)
              if (!workDayJson.containsKey('date')) {
                workDayJson['date'] = DateTime.now().toIso8601String();
              }
              return WorkDayModel.fromJson(workDayJson);
            }()
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'business': business.toJson(),
      'employment': employment.toJson(),
      'employeeData': employeeData.toJson(),
      'orgStructure': orgStructure.toJson(),
      if (interchangeableEmployee != null)
        'interchangeableEmployee': interchangeableEmployee!.toJson(),
      'hrDocuments': hrDocuments.map((doc) => doc.toJson()).toList(),
      if (workDay != null) 'workDay': workDay!.toJson(),
    };
  }

  UserProfile toEntity() {
    return UserProfile(
      user: user.toEntity(),
      business: business.toEntity(),
      employment: employment.toEntity(),
      employeeData: employeeData.toEntity(),
      orgStructure: orgStructure.toEntity(),
      interchangeableEmployee: interchangeableEmployee?.toEntity(),
      hrDocuments: hrDocuments.map((doc) => doc.toEntity()).toList(),
      workDay: workDay?.toEntity(),
    );
  }
}

/// Модель пользователя в профиле
class ProfileUserModel implements Model {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? patronymic;
  final String? phone;

  ProfileUserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.phone,
  });

  factory ProfileUserModel.fromJson(Map<String, dynamic> json) {
    return ProfileUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (patronymic != null) 'patronymic': patronymic,
      if (phone != null) 'phone': phone,
    };
  }

  ProfileUser toEntity() {
    return ProfileUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      patronymic: patronymic,
      phone: phone,
    );
  }
}

/// Модель трудоустройства
class EmploymentModel implements Model {
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

  EmploymentModel({
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

  factory EmploymentModel.fromJson(Map<String, dynamic> json) {
    return EmploymentModel(
      id: json['id'] as String,
      position: json['position'] as String?,
      positionType: json['positionType'] as String?,
      orgPosition: json['orgPosition'] as String?,
      department: json['department'] as String?,
      hireDate:
          json['hireDate'] != null
              ? DateTime.parse(json['hireDate'] as String)
              : null,
      workPhone: json['workPhone'] as String?,
      workExperience: json['workExperience'] as String?,
      accountability: json['accountability'] as String?,
      personnelNumber: json['personnelNumber'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (position != null) 'position': position,
      if (positionType != null) 'positionType': positionType,
      if (orgPosition != null) 'orgPosition': orgPosition,
      if (department != null) 'department': department,
      if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
      if (workPhone != null) 'workPhone': workPhone,
      if (workExperience != null) 'workExperience': workExperience,
      if (accountability != null) 'accountability': accountability,
      if (personnelNumber != null) 'personnelNumber': personnelNumber,
      'isActive': isActive,
    };
  }

  Employment toEntity() {
    return Employment(
      id: id,
      position: position,
      positionType: positionType,
      orgPosition: orgPosition,
      department: department,
      hireDate: hireDate,
      workPhone: workPhone,
      workExperience: workExperience,
      accountability: accountability,
      personnelNumber: personnelNumber,
      isActive: isActive,
    );
  }
}

/// Модель данных сотрудника
class EmployeeDataModel implements Model {
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

  EmployeeDataModel({
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

  factory EmployeeDataModel.fromJson(Map<String, dynamic> json) {
    return EmployeeDataModel(
      photo: json['photo'] as String?,
      lastName: json['lastName'] as String?,
      firstName: json['firstName'] as String?,
      patronymic: json['patronymic'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      hireDate:
          json['hireDate'] != null
              ? DateTime.parse(json['hireDate'] as String)
              : null,
      positionType: json['positionType'] as String?,
      email: json['email'] as String?,
      workPhone: json['workPhone'] as String?,
      workExperience: json['workExperience'] as String?,
      accountability: json['accountability'] as String?,
      personnelNumber: json['personnelNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (photo != null) 'photo': photo,
      if (lastName != null) 'lastName': lastName,
      if (firstName != null) 'firstName': firstName,
      if (patronymic != null) 'patronymic': patronymic,
      if (department != null) 'department': department,
      if (position != null) 'position': position,
      if (hireDate != null) 'hireDate': hireDate!.toIso8601String(),
      if (positionType != null) 'positionType': positionType,
      if (email != null) 'email': email,
      if (workPhone != null) 'workPhone': workPhone,
      if (workExperience != null) 'workExperience': workExperience,
      if (accountability != null) 'accountability': accountability,
      if (personnelNumber != null) 'personnelNumber': personnelNumber,
    };
  }

  EmployeeData toEntity() {
    return EmployeeData(
      photo: photo,
      lastName: lastName,
      firstName: firstName,
      patronymic: patronymic,
      department: department,
      position: position,
      hireDate: hireDate,
      positionType: positionType,
      email: email,
      workPhone: workPhone,
      workExperience: workExperience,
      accountability: accountability,
      personnelNumber: personnelNumber,
    );
  }
}

/// Модель организационной структуры
class OrgStructureModel implements Model {
  final bool isGeneralDirector;
  final bool isProjectManager;
  final bool isDepartmentHead;
  final bool isEmployee;
  final String? currentPosition;

  OrgStructureModel({
    required this.isGeneralDirector,
    required this.isProjectManager,
    required this.isDepartmentHead,
    required this.isEmployee,
    this.currentPosition,
  });

  factory OrgStructureModel.fromJson(Map<String, dynamic> json) {
    return OrgStructureModel(
      isGeneralDirector: json['isGeneralDirector'] as bool? ?? false,
      isProjectManager: json['isProjectManager'] as bool? ?? false,
      isDepartmentHead: json['isDepartmentHead'] as bool? ?? false,
      isEmployee: json['isEmployee'] as bool? ?? false,
      currentPosition: json['currentPosition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isGeneralDirector': isGeneralDirector,
      'isProjectManager': isProjectManager,
      'isDepartmentHead': isDepartmentHead,
      'isEmployee': isEmployee,
      if (currentPosition != null) 'currentPosition': currentPosition,
    };
  }

  OrgStructure toEntity() {
    return OrgStructure(
      isGeneralDirector: isGeneralDirector,
      isProjectManager: isProjectManager,
      isDepartmentHead: isDepartmentHead,
      isEmployee: isEmployee,
      currentPosition: currentPosition,
    );
  }
}

/// Модель взаимозаменяемого сотрудника
class InterchangeableEmployeeModel implements Model {
  final String id;
  final String fullName;

  InterchangeableEmployeeModel({required this.id, required this.fullName});

  factory InterchangeableEmployeeModel.fromJson(Map<String, dynamic> json) {
    return InterchangeableEmployeeModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'fullName': fullName};
  }

  InterchangeableEmployee toEntity() {
    return InterchangeableEmployee(id: id, fullName: fullName);
  }
}

/// Модель кадрового документа
class HrDocumentModel implements Model {
  final String id;
  final String type;
  final String title;
  final String? fileUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  HrDocumentModel({
    required this.id,
    required this.type,
    required this.title,
    this.fileUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HrDocumentModel.fromJson(Map<String, dynamic> json) {
    return HrDocumentModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      fileUrl: json['fileUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      if (fileUrl != null) 'fileUrl': fileUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  HrDocument toEntity() {
    return HrDocument(
      id: id,
      type: type,
      title: title,
      fileUrl: fileUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
