import '../../domain/entities/auth_user.dart';
import '../../domain/entities/approval_permission.dart';
import '../models/model.dart';

/// Модель ответа аутентификации
class AuthResponse implements Model {
  final AuthUserModel user;
  final String accessToken;
  final String refreshToken;
  final List<ApprovalPermissionModel> approvalPermissions;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.approvalPermissions = const [],
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final permissionsList = json['approvalPermissions'] as List<dynamic>?;
    final permissions = permissionsList
            ?.map((e) =>
                ApprovalPermissionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AuthResponse(
      user: AuthUserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      approvalPermissions: permissions,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'approvalPermissions': approvalPermissions.map((e) => e.toJson()).toList(),
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

  ManagedDepartmentModel({
    required this.id,
    required this.name,
  });

  factory ManagedDepartmentModel.fromJson(Map<String, dynamic> json) {
    return ManagedDepartmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  ManagedDepartment toEntity() {
    return ManagedDepartment(id: id, name: name);
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

  AuthUserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.isAdmin,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'id': id, 'email': email, 'username': username, 'isAdmin': isAdmin};
  }

  /// Преобразование в доменную сущность
  AuthUser toEntity([List<ApprovalPermission> approvalPermissions = const []]) {
    return AuthUser(
      id: id,
      email: email,
      username: username,
      isAdmin: isAdmin,
      approvalPermissions: approvalPermissions,
    );
  }
}
