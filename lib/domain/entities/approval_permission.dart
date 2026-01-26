import '../entities/entity.dart';
import 'department.dart';

/// Департамент, которым управляет пользователь
class ManagedDepartment extends Entity {
  final String id;
  final String name;
  final DepartmentCode? code; // Код типа департамента

  const ManagedDepartment({
    required this.id,
    required this.name,
    this.code,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManagedDepartment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ (code?.hashCode ?? 0);

  @override
  String toString() => 'ManagedDepartment(id: $id, name: $name, code: $code)';
}

/// Права пользователя на согласование в конкретном бизнесе
class ApprovalPermission extends Entity {
  final String businessId;
  final String businessName;
  final bool canApprove;
  final bool isDepartmentManager;
  final bool isGeneralDirector;
  final bool isAuthorizedApprover;
  final List<ManagedDepartment> managedDepartments;

  const ApprovalPermission({
    required this.businessId,
    required this.businessName,
    required this.canApprove,
    required this.isDepartmentManager,
    required this.isGeneralDirector,
    required this.isAuthorizedApprover,
    required this.managedDepartments,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalPermission &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          businessName == other.businessName &&
          canApprove == other.canApprove &&
          isDepartmentManager == other.isDepartmentManager &&
          isGeneralDirector == other.isGeneralDirector &&
          isAuthorizedApprover == other.isAuthorizedApprover;

  @override
  int get hashCode =>
      businessId.hashCode ^
      businessName.hashCode ^
      canApprove.hashCode ^
      isDepartmentManager.hashCode ^
      isGeneralDirector.hashCode ^
      isAuthorizedApprover.hashCode;

  @override
  String toString() =>
      'ApprovalPermission(businessId: $businessId, businessName: $businessName, canApprove: $canApprove, isDepartmentManager: $isDepartmentManager, isGeneralDirector: $isGeneralDirector, isAuthorizedApprover: $isAuthorizedApprover, managedDepartments: $managedDepartments)';
}





