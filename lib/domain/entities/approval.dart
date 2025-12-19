import '../entities/entity.dart';
import 'business.dart';
import 'user_profile.dart';
import 'approval_template.dart';
import 'approval_comment.dart';
import 'approval_attachment.dart';
import 'approval_decision.dart';
import 'approval_process_type.dart';

/// Статус согласования
enum ApprovalStatus {
  pending, // Ожидает согласования
  approved, // Одобрено
  rejected, // Отклонено
  cancelled, // Отменено
}

/// Согласование
class Approval extends Entity {
  final String id;
  final String businessId;
  final String? templateId;
  final String? templateCode; // Код шаблона
  final String title;
  final String? description;
  final ApprovalStatus status;
  final String createdBy; // ID создателя
  final DateTime? requestDate; // Дата запроса
  final Map<String, dynamic>? formData; // Данные формы
  final DateTime createdAt;
  final DateTime updatedAt;
  final ApprovalProcessType? processType; // Тип процесса согласования (deprecated, используйте templateCode)
  
  // Связанные данные
  final Business? business;
  final ApprovalTemplate? template;
  final ProfileUser? creator;
  final List<ApprovalDecision>? decisions;
  final List<ApprovalComment>? comments;
  final List<ApprovalAttachment>? attachments;
  final List<ApprovalApprover>? approvers; // Список тех, кто может одобрить

  const Approval({
    required this.id,
    required this.businessId,
    this.templateId,
    this.templateCode,
    required this.title,
    this.description,
    this.status = ApprovalStatus.pending,
    required this.createdBy,
    this.requestDate,
    this.formData,
    required this.createdAt,
    required this.updatedAt,
    this.processType,
    this.business,
    this.template,
    this.creator,
    this.decisions,
    this.comments,
    this.attachments,
    this.approvers,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Approval &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Approval(id: $id, title: $title)';
}

/// Одобряющий (тот, кто может одобрить согласование)
class ApprovalApprover {
  final String id;
  final String approvalId;
  final String userId;
  final int stepOrder;
  final bool isRequired;
  final DateTime createdAt;
  final ProfileUser? user;

  const ApprovalApprover({
    required this.id,
    required this.approvalId,
    required this.userId,
    required this.stepOrder,
    this.isRequired = true,
    required this.createdAt,
    this.user,
  });
}

