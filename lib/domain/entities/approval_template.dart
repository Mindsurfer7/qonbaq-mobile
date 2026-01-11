import '../entities/entity.dart';
import 'business.dart';

/// Категория шаблона
enum ApprovalTemplateCategory {
  financial,
  hr,
  document,
  other,
}

/// Тип workflow
enum WorkflowType {
  sequential, // Последовательное
  parallel, // Параллельное
  conditional, // Условное
}

/// Шаблон согласования
class ApprovalTemplate extends Entity {
  final String id;
  final String businessId;
  final String code; // Код шаблона (например, CASHLESS_PAYMENT_REQUEST)
  final String name;
  final String? description;
  final ApprovalTemplateCategory? category;
  final Map<String, dynamic>? formSchema; // Схема формы для рендеринга
  final WorkflowType? workflowType;
  final Map<String, dynamic>? workflowConfig; // Конфигурация workflow
  final String? finalApproverRole; // Роль финального одобряющего
  final String? executorDepartment; // Отдел исполнителя
  final String? executorRole; // Код роли исполнителя
  final String? executorAction; // Действие исполнителя
  final bool isActive;
  final List<ApprovalStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Business? business;

  const ApprovalTemplate({
    required this.id,
    required this.businessId,
    required this.code,
    required this.name,
    this.description,
    this.category,
    this.formSchema,
    this.workflowType,
    this.workflowConfig,
    this.finalApproverRole,
    this.executorDepartment,
    this.executorRole,
    this.executorAction,
    this.isActive = true,
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
    this.business,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ApprovalTemplate(id: $id, name: $name)';
}

/// Шаг согласования в шаблоне
class ApprovalStep {
  final int order;
  final ApprovalStepType type;
  final String? departmentId;
  final String? userId;
  final bool isRequired;

  const ApprovalStep({
    required this.order,
    required this.type,
    this.departmentId,
    this.userId,
    this.isRequired = true,
  });
}

/// Тип шага согласования
enum ApprovalStepType {
  user, // Конкретный пользователь
  department, // Отдел
  manager, // Менеджер
}

