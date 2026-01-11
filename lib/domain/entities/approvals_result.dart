import 'approval.dart';

/// Результат получения согласований с метаданными
class ApprovalsResult {
  final List<Approval> approvals;
  final List<UnassignedRoleInfo>? unassignedRoles;
  final String? message;

  ApprovalsResult({
    required this.approvals,
    this.unassignedRoles,
    this.message,
  });
}

/// Информация о неназначенной роли
class UnassignedRoleInfo {
  final String code;
  final String name;

  UnassignedRoleInfo({
    required this.code,
    required this.name,
  });
}
