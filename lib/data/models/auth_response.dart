import '../../domain/entities/auth_user.dart';
import '../../domain/entities/approval_permission.dart';
import '../../domain/entities/department.dart';
import '../models/model.dart';

/// Модель ответа аутентификации
class AuthResponse implements Model {
  final AuthUserModel user;
  final String accessToken;
  final String refreshToken;
  final List<ApprovalPermissionModel> approvalPermissions;
  final GuestBusinessModel? business;
  final bool isReadOnly;
  final String? expiresIn;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.approvalPermissions = const [],
    this.business,
    this.isReadOnly = false,
    this.expiresIn,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['approvalPermissions'] as List<dynamic>?;
    final permissions = permissionsList
            ?.map((e) =>
                ApprovalPermissionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    GuestBusinessModel? business;
    if (json['business'] != null) {
      business = GuestBusinessModel.fromJson(
        json['business'] as Map<String, dynamic>,
      );
    }

    return AuthResponse(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      approvalPermissions: permissions,
      business: business,
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      expiresIn: json['expiresIn'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'approvalPermissions': approvalPermissions.map((e) => e.toJson()).toList(),
      if (business != null) 'business': business!.toJson(),
      'isReadOnly': isReadOnly,
      if (expiresIn != null) 'expiresIn': expiresIn,
    };
  }

  /// Преобразование в доменную сущность пользователя
  AuthUser toUserEntity() {
    return user.toEntity(
      approvalPermissions.map((e) => e.toEntity()).toList(),
    );
  }
}

/// Модель департамента
class ManagedDepartmentModel implements Model {
  final String id;
  final String name;
  final DepartmentCode? code;

  ManagedDepartmentModel({
    required this.id,
    required this.name,
    this.code,
  });

  factory ManagedDepartmentModel.fromJson(Map<String, dynamic> json) {
    // Парсим code
    DepartmentCode? code;
    if (json['code'] != null) {
      code = _parseDepartmentCode(json['code'] as String);
    }

    return ManagedDepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: code,
    );
  }

  static DepartmentCode? _parseDepartmentCode(String codeStr) {
    switch (codeStr.toUpperCase()) {
      case 'ADMINISTRATION':
        return DepartmentCode.administration;
      case 'SALES':
        return DepartmentCode.sales;
      case 'ACCOUNTING':
        return DepartmentCode.accounting;
      case 'PRODUCTION':
        return DepartmentCode.production;
      case 'CUSTOM':
        return DepartmentCode.custom;
      default:
        return null;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': _departmentCodeToString(code),
    };
  }

  static String? _departmentCodeToString(DepartmentCode? code) {
    if (code == null) return null;
    switch (code) {
      case DepartmentCode.administration:
        return 'ADMINISTRATION';
      case DepartmentCode.sales:
        return 'SALES';
      case DepartmentCode.accounting:
        return 'ACCOUNTING';
      case DepartmentCode.production:
        return 'PRODUCTION';
      case DepartmentCode.custom:
        return 'CUSTOM';
    }
  }

  ManagedDepartment toEntity() {
    return ManagedDepartment(id: id, name: name, code: code);
  }
}

/// Модель прав на согласование
class ApprovalPermissionModel implements Model {
  final String businessId;
  final String businessName;
  final bool canApprove;
  final bool isDepartmentManager;
  final bool isGeneralDirector;
  final bool isAuthorizedApprover;
  final List<ManagedDepartmentModel> managedDepartments;

  ApprovalPermissionModel({
    required this.businessId,
    required this.businessName,
    required this.canApprove,
    required this.isDepartmentManager,
    required this.isGeneralDirector,
    required this.isAuthorizedApprover,
    this.managedDepartments = const [],
  });

  factory ApprovalPermissionModel.fromJson(Map<String, dynamic> json) {
    final departmentsList = json['managedDepartments'] as List<dynamic>?;
    final departments = departmentsList
            ?.map((e) =>
                ManagedDepartmentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ApprovalPermissionModel(
      businessId: json['businessId'] as String,
      businessName: json['businessName'] as String,
      canApprove: json['canApprove'] as bool? ?? false,
      isDepartmentManager: json['isDepartmentManager'] as bool? ?? false,
      isGeneralDirector: json['isGeneralDirector'] as bool? ?? false,
      isAuthorizedApprover: json['isAuthorizedApprover'] as bool? ?? false,
      managedDepartments: departments,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'canApprove': canApprove,
      'isDepartmentManager': isDepartmentManager,
      'isGeneralDirector': isGeneralDirector,
      'isAuthorizedApprover': isAuthorizedApprover,
      'managedDepartments': managedDepartments.map((e) => e.toJson()).toList(),
    };
  }

  ApprovalPermission toEntity() {
    return ApprovalPermission(
      businessId: businessId,
      businessName: businessName,
      canApprove: canApprove,
      isDepartmentManager: isDepartmentManager,
      isGeneralDirector: isGeneralDirector,
      isAuthorizedApprover: isAuthorizedApprover,
      managedDepartments: managedDepartments.map((e) => e.toEntity()).toList(),
    );
  }
}

/// Модель пользователя в ответе аутентификации
class AuthUserModel implements Model {
  final String id;
  final String email;
  final String username;
  final bool isAdmin;
  final bool isGuest;

  AuthUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isAdmin,
    this.isGuest = false,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'isAdmin': isAdmin,
      'isGuest': isGuest,
    };
  }

  /// Преобразование в доменную сущность
  AuthUser toEntity([List<ApprovalPermission> approvalPermissions = const []]) {
    return AuthUser(
      id: id,
      email: email,
      username: username,
      isAdmin: isAdmin,
      isGuest: isGuest,
      approvalPermissions: approvalPermissions,
    );
  }
}

/// Модель бизнеса для гостевой сессии
class GuestBusinessModel implements Model {
  final String id;
  final String name;
  final String? description;

  GuestBusinessModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory GuestBusinessModel.fromJson(Map<String, dynamic> json) {
    return GuestBusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
    };
  }
}
