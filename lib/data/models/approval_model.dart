import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_process_type.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/approval_attachment.dart';
import '../../domain/entities/approval_decision.dart';
import '../../domain/entities/department.dart';
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
    required super.paymentDueDate,
    super.amount,
    super.formData,
    required super.createdAt,
    required super.updatedAt,
    super.processType,
    super.business,
    super.template,
    super.creator,
    super.initiator,
    super.currentApprover,
    super.currentDepartment,
    super.selectedExecutor,
    super.decisions,
    super.comments,
    super.attachments,
    super.approvers,
    super.potentialExecutors,
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
    // Поддерживаем оба варианта: creator и initiator
    final creatorJson = json['creator'] as Map<String, dynamic>?;
    if (creatorJson != null) {
      creator = ProfileUser(
        id: creatorJson['id'] as String,
        email: creatorJson['email'] as String,
        firstName: creatorJson['firstName'] as String?,
        lastName: creatorJson['lastName'] as String?,
        patronymic: creatorJson['patronymic'] as String?,
        phone: creatorJson['phone'] as String?,
      );
    }

    // Инициатор (может отличаться от creator)
    ProfileUser? initiator;
    final initiatorJson = json['initiator'] as Map<String, dynamic>?;
    if (initiatorJson != null) {
      initiator = ProfileUser(
        id: initiatorJson['id'] as String,
        email: initiatorJson['email'] as String,
        firstName: initiatorJson['firstName'] as String?,
        lastName: initiatorJson['lastName'] as String?,
        patronymic: initiatorJson['patronymic'] as String?,
        phone: initiatorJson['phone'] as String?,
      );
    }

    ProfileUser? currentApprover;
    if (json['currentApprover'] != null) {
      final currentApproverJson = json['currentApprover'] as Map<String, dynamic>;
      currentApprover = ProfileUser(
        id: currentApproverJson['id'] as String,
        email: currentApproverJson['email'] as String,
        firstName: currentApproverJson['firstName'] as String?,
        lastName: currentApproverJson['lastName'] as String?,
        patronymic: currentApproverJson['patronymic'] as String?,
        phone: currentApproverJson['phone'] as String?,
      );
    }

    // Текущий департамент
    DepartmentInfo? currentDepartment;
    if (json['currentDepartment'] != null) {
      final currentDepartmentJson = json['currentDepartment'] as Map<String, dynamic>;
      // Для currentDepartment используем DepartmentInfo, manager не входит в DepartmentInfo
      currentDepartment = DepartmentInfo(
        id: currentDepartmentJson['id'] as String,
        name: currentDepartmentJson['name'] as String,
        description: currentDepartmentJson['description'] as String?,
      );
    }

    // Выбранный исполнитель
    ProfileUser? selectedExecutor;
    if (json['selectedExecutor'] != null) {
      final selectedExecutorJson = json['selectedExecutor'] as Map<String, dynamic>;
      selectedExecutor = ProfileUser(
        id: selectedExecutorJson['id'] as String,
        email: selectedExecutorJson['email'] as String,
        firstName: selectedExecutorJson['firstName'] as String?,
        lastName: selectedExecutorJson['lastName'] as String?,
        patronymic: selectedExecutorJson['patronymic'] as String?,
        phone: selectedExecutorJson['phone'] as String?,
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

    // Потенциальные исполнители
    List<ProfileUser>? potentialExecutors;
    if (json['potentialExecutors'] != null) {
      final executorsList = json['potentialExecutors'] as List<dynamic>;
      potentialExecutors = executorsList.map((e) {
        final executorJson = e as Map<String, dynamic>;
        return ProfileUser(
          id: executorJson['id'] as String,
          email: executorJson['email'] as String,
          firstName: executorJson['firstName'] as String?,
          lastName: executorJson['lastName'] as String?,
          patronymic: executorJson['patronymic'] as String?,
          phone: executorJson['phone'] as String?,
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

    // Поддерживаем оба варианта: createdBy и initiatorId
    final createdById = json['createdBy'] as String? ?? json['initiatorId'] as String?;
    if (createdById == null || createdById.isEmpty) {
      throw FormatException('Поле createdBy или initiatorId обязательно для Approval. JSON: $json');
    }

    // Проверяем обязательные поля
    final id = json['id'];
    if (id == null || id is! String) {
      throw FormatException('Поле id обязательно и должно быть String, получено: $id (${id.runtimeType})');
    }
    
    final businessIdValue = json['businessId'];
    if (businessIdValue == null || businessIdValue is! String) {
      throw FormatException('Поле businessId обязательно и должно быть String, получено: $businessIdValue (${businessIdValue.runtimeType})');
    }
    
    return ApprovalModel(
      id: id,
      businessId: businessIdValue,
      templateId: json['templateId'] as String?,
      templateCode: json['templateCode'] as String?,
      title: json['title'] as String? ?? 'Без названия',
      description: json['description'] as String?,
      status: json['status'] != null 
          ? _parseStatus(json['status'].toString()) // Используем toString() для надежности
          : (() {
              // Если статус не указан, выводим предупреждение
              print('⚠️ Статус согласования не указан в JSON. ID: ${json['id']}. Используется статус по умолчанию: pending');
              return ApprovalStatus.pending;
            })(), // По умолчанию, если статус не указан
      createdBy: createdById,
      paymentDueDate: json['paymentDueDate'] != null
          ? DateTime.parse(json['paymentDueDate'] as String)
          : (throw FormatException('Поле paymentDueDate обязательно для Approval')),
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      formData: formData,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(), // По умолчанию текущее время, если не указано
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(), // По умолчанию текущее время, если не указано
      processType: processType,
      business: business,
      template: template,
      creator: creator,
      initiator: initiator,
      currentApprover: currentApprover,
      currentDepartment: currentDepartment,
      selectedExecutor: selectedExecutor,
      decisions: decisions,
      comments: comments,
      attachments: attachments,
      approvers: approvers,
      potentialExecutors: potentialExecutors,
    );
  }

  static ApprovalStatus _parseStatus(String status) {
    // Убираем пробелы и приводим к верхнему регистру
    final normalizedStatus = status.trim().toUpperCase();
    
    switch (normalizedStatus) {
      case 'DRAFT':
        return ApprovalStatus.draft;
      case 'PENDING':
        return ApprovalStatus.pending;
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'REJECTED':
        return ApprovalStatus.rejected;
      case 'IN_EXECUTION':
      case 'INEXECUTION':
        return ApprovalStatus.inExecution;
      case 'AWAITING_CONFIRMATION':
      case 'AWAITINGCONFIRMATION':
        return ApprovalStatus.awaitingConfirmation;
      case 'COMPLETED':
        return ApprovalStatus.completed;
      case 'CANCELLED':
      case 'CANCELED':
        return ApprovalStatus.cancelled;
      default:
        // Если статус не распознан, выводим предупреждение и возвращаем pending
        print('⚠️ Неизвестный статус согласования: "$status" (нормализован: "$normalizedStatus"). Используется статус по умолчанию: pending');
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
      case ApprovalStatus.awaitingConfirmation:
        return 'AWAITING_CONFIRMATION';
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
      'paymentDueDate': paymentDueDate.toUtc().toIso8601String(),
      if (formData != null) 'formData': formData,
      if (processType != null) 'processType': processType!.code,
    };
  }

  /// JSON для обновления согласования (все поля опциональны)
  /// Согласно API: title, projectId, amount, formData
  Map<String, dynamic> toUpdateJson({
    String? title,
    String? projectId,
    double? amount,
    Map<String, dynamic>? formData,
  }) {
    final result = <String, dynamic>{};
    
    if (title != null && title.isNotEmpty) {
      result['title'] = title;
    }
    
    if (projectId != null && projectId.isNotEmpty) {
      result['projectId'] = projectId;
    }
    
    if (amount != null) {
      result['amount'] = amount;
    }
    
    if (formData != null) {
      result['formData'] = formData;
    }
    
    return result;
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
      paymentDueDate: paymentDueDate,
      amount: amount,
      formData: formData,
      createdAt: createdAt,
      updatedAt: updatedAt,
      processType: processType,
      business: business,
      template: template,
      creator: creator,
      initiator: initiator,
      currentApprover: currentApprover,
      currentDepartment: currentDepartment,
      selectedExecutor: selectedExecutor,
      decisions: decisions,
      comments: comments,
      attachments: attachments,
      approvers: approvers,
      potentialExecutors: potentialExecutors,
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
      paymentDueDate: approval.paymentDueDate,
      amount: approval.amount,
      formData: approval.formData,
      createdAt: approval.createdAt,
      updatedAt: approval.updatedAt,
      processType: approval.processType,
      business: approval.business,
      template: approval.template,
      creator: approval.creator,
      initiator: approval.initiator,
      currentApprover: approval.currentApprover,
      currentDepartment: approval.currentDepartment,
      selectedExecutor: approval.selectedExecutor,
      decisions: approval.decisions,
      comments: approval.comments,
      attachments: approval.attachments,
      approvers: approval.approvers,
      potentialExecutors: approval.potentialExecutors,
    );
  }
}

