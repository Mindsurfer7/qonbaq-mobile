import '../entities/entity.dart';
import 'approval_permission.dart';

/// Доменная сущность аутентифицированного пользователя
class AuthUser extends Entity {
  final String id;
  final String email;
  final String username;
  final bool isAdmin;
  final List<ApprovalPermission> approvalPermissions;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.isAdmin,
    this.approvalPermissions = const [],
  });

  /// Проверка, может ли пользователь согласовывать в конкретном бизнесе
  bool canApproveInBusiness(String businessId) {
    return approvalPermissions.any(
      (perm) => perm.businessId == businessId && perm.canApprove,
    );
  }

  /// Проверка, может ли пользователь согласовывать хотя бы в одном бизнесе
  bool get canApproveAnywhere =>
      approvalPermissions.any((perm) => perm.canApprove);

  /// Получение прав для конкретного бизнеса
  ApprovalPermission? getPermissionsForBusiness(String businessId) {
    try {
      return approvalPermissions.firstWhere(
        (perm) => perm.businessId == businessId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          isAdmin == other.isAdmin;

  @override
  int get hashCode =>
      id.hashCode ^ email.hashCode ^ username.hashCode ^ isAdmin.hashCode;

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, username: $username, isAdmin: $isAdmin, approvalPermissions: ${approvalPermissions.length})';
}
