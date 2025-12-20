import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_process_type.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/approval_attachment.dart';
import '../../domain/entities/approval_decision.dart';
import '../models/model.dart';
import 'approval_template_model.dart';
import 'approval_comment_model.dart';
import 'approval_attachment_model.dart';
import 'approval_decision_model.dart';
import 'dart:convert';

/// Модель согласования
class ApprovalModel extends Approval implements Model {
  const ApprovalModel({
    required super.id,
    required super.businessId,
    super.templateId,
    super.templateCode,
    required super.title,
    super.description,
    super.status,
    required super.createdBy,
    super.requestDate,
    super.formData,
    required super.createdAt,
    required super.updatedAt,
    super.processType,
    super.business,
    super.template,
    super.creator,
    super.decisions,
    super.comments,
    super.attachments,
    super.approvers,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    Business? business;
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = Business(
        id: businessJson['id'] as String,
        name: businessJson['name'] as String,
      );
    }

    ApprovalTemplate? template;
    if (json['template'] != null) {
      template = ApprovalTemplateModel.fromJson(
        json['template'] as Map<String, dynamic>,
      ).toEntity();
    }

    ProfileUser? creator;
    if (json['creator'] != null) {
      final creatorJson = json['creator'] as Map<String, dynamic>;
      creator = ProfileUser(
        id: creatorJson['id'] as String,
        email: creatorJson['email'] as String,
        firstName: creatorJson['firstName'] as String?,
        lastName: creatorJson['lastName'] as String?,
        patronymic: creatorJson['patronymic'] as String?,
        phone: creatorJson['phone'] as String?,
      );
    }

    List<ApprovalDecision>? decisions;
    if (json['decisions'] != null) {
      final decisionsList = json['decisions'] as List<dynamic>;
      decisions = decisionsList
          .map((d) => ApprovalDecisionModel.fromJson(d as Map<String, dynamic>).toEntity())
          .toList();
    }

    List<ApprovalComment>? comments;
    if (json['comments'] != null) {
      final commentsList = json['comments'] as List<dynamic>;
      comments = commentsList
          .map((c) => ApprovalCommentModel.fromJson(c as Map<String, dynamic>).toEntity())
          .toList();
    }

    List<ApprovalAttachment>? attachments;
    if (json['attachments'] != null) {
      final attachmentsList = json['attachments'] as List<dynamic>;
      attachments = attachmentsList
          .map((a) => ApprovalAttachmentModel.fromJson(a as Map<String, dynamic>).toEntity())
          .toList();
    }

    List<ApprovalApprover>? approvers;
    if (json['approvers'] != null) {
      final approversList = json['approvers'] as List<dynamic>;
      approvers = approversList.map((a) {
        ProfileUser? user;
        if (a['user'] != null) {
          final userJson = a['user'] as Map<String, dynamic>;
          user = ProfileUser(
            id: userJson['id'] as String,
            email: userJson['email'] as String,
            firstName: userJson['firstName'] as String?,
            lastName: userJson['lastName'] as String?,
            patronymic: userJson['patronymic'] as String?,
            phone: userJson['phone'] as String?,
          );
        }
        return ApprovalApprover(
          id: a['id'] as String,
          approvalId: a['approvalId'] as String,
          userId: a['userId'] as String,
          stepOrder: a['stepOrder'] as int,
          isRequired: a['isRequired'] as bool? ?? true,
          createdAt: DateTime.parse(a['createdAt'] as String),
          user: user,
        );
      }).toList();
    }

    // Парсинг типа процесса
    ApprovalProcessType? processType;
    if (json['processType'] != null) {
      processType = ApprovalProcessType.fromCode(json['processType'] as String);
    }

    // Парсинг formData
    Map<String, dynamic>? formData;
    if (json['formData'] != null) {
      if (json['formData'] is Map) {
        formData = json['formData'] as Map<String, dynamic>;
      } else if (json['formData'] is String) {
        try {
          formData = jsonDecode(json['formData'] as String) as Map<String, dynamic>;
        } catch (e) {
          // Если не удалось распарсить, оставляем null
        }
      }
    }

    return ApprovalModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      templateId: json['templateId'] as String?,
      templateCode: json['templateCode'] as String?,
      title: json['title'] as String? ?? 'Без названия',
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String),
      createdBy: json['createdBy'] as String,
      requestDate: json['requestDate'] != null
          ? DateTime.parse(json['requestDate'] as String)
          : null,
      formData: formData,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      processType: processType,
      business: business,
      template: template,
      creator: creator,
      decisions: decisions,
      comments: comments,
      attachments: attachments,
      approvers: approvers,
    );
  }

  static ApprovalStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return ApprovalStatus.draft;
      case 'PENDING':
        return ApprovalStatus.pending;
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      case 'IN_EXECUTION':
        return ApprovalStatus.inExecution;
      case 'COMPLETED':
        return ApprovalStatus.completed;
      case 'CANCELLED':
        return ApprovalStatus.cancelled;
      default:
        return ApprovalStatus.pending;
    }
  }

  static String _statusToString(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return 'DRAFT';
      case ApprovalStatus.pending:
        return 'PENDING';
      case ApprovalStatus.approved:
        return 'APPROVED';
      case ApprovalStatus.rejected:
        return 'REJECTED';
      case ApprovalStatus.inExecution:
        return 'IN_EXECUTION';
      case ApprovalStatus.completed:
        return 'COMPLETED';
      case ApprovalStatus.cancelled:
        return 'CANCELLED';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      if (templateId != null) 'templateId': templateId,
      'title': title,
      if (description != null) 'description': description,
      'status': _statusToString(status),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (processType != null) 'processType': processType!.code,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      if (templateId != null) 'templateId': templateId,
      if (templateCode != null) 'templateCode': templateCode,
      'title': title,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (requestDate != null) 'requestDate': requestDate!.toUtc().toIso8601String(),
      if (formData != null) 'formData': formData,
      if (processType != null) 'processType': processType!.code,
    };
  }

  Approval toEntity() {
    return Approval(
      id: id,
      businessId: businessId,
      templateId: templateId,
      templateCode: templateCode,
      title: title,
      description: description,
      status: status,
      createdBy: createdBy,
      requestDate: requestDate,
      formData: formData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      processType: processType,
      business: business,
      template: template,
      creator: creator,
      decisions: decisions,
      comments: comments,
      attachments: attachments,
      approvers: approvers,
    );
  }

  factory ApprovalModel.fromEntity(Approval approval) {
    return ApprovalModel(
      id: approval.id,
      businessId: approval.businessId,
      templateId: approval.templateId,
      templateCode: approval.templateCode,
      title: approval.title,
      description: approval.description,
      status: approval.status,
      createdBy: approval.createdBy,
      requestDate: approval.requestDate,
      formData: approval.formData,
      createdAt: approval.createdAt,
      updatedAt: approval.updatedAt,
      processType: approval.processType,
      business: approval.business,
      template: approval.template,
      creator: approval.creator,
      decisions: approval.decisions,
      comments: approval.comments,
      attachments: approval.attachments,
      approvers: approval.approvers,
    );
  }
}

