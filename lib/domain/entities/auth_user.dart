import '../entities/entity.dart';
import 'approval_permission.dart';
import 'department.dart';

/// Доменная сущность аутентифицированного пользователя
class AuthUser extends Entity {
  final String id;
  final String email;
  final String username;
  final bool isAdmin;
  final bool isGuest;
  final List<ApprovalPermission> approvalPermissions;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.isAdmin,
    this.isGuest = false,
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

  /// Проверка, является ли пользователь руководителем отдела продаж (РОП) в конкретном бизнесе
  /// РОП - это менеджер департамента с кодом SALES
  /// Если код еще не приходит с бэкенда, проверяем по имени департамента
  bool isSalesDepartmentHead(String businessId) {
    final permission = getPermissionsForBusiness(businessId);
    if (permission == null || !permission.isDepartmentManager) {
      return false;
    }

    // Проверяем, есть ли среди управляемых департаментов департамент с кодом SALES
    final hasSalesCode = permission.managedDepartments.any(
      (dept) => dept.code == DepartmentCode.sales,
    );
    
    if (hasSalesCode) {
      return true;
    }

    // Fallback: проверяем по имени департамента, если код еще не приходит
    // Ищем департаменты с названиями, содержащими "продаж" или "sales"
    final salesDepartmentNames = [
      'отдел продаж',
      'отдел продаж и маркетинга',
      'отдел продаж и сбыта',
      'продажи',
      'sales',
    ];
    
    return permission.managedDepartments.any(
      (dept) {
        final deptNameLower = dept.name.toLowerCase();
        return salesDepartmentNames.any(
          (salesName) => deptNameLower.contains(salesName.toLowerCase()),
        );
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          username == other.username &&
          isAdmin == other.isAdmin &&
          isGuest == other.isGuest;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      username.hashCode ^
      isAdmin.hashCode ^
      isGuest.hashCode;

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, username: $username, isAdmin: $isAdmin, isGuest: $isGuest, approvalPermissions: ${approvalPermissions.length})';
}
