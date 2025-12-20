import '../../domain/entities/approval_template.dart';
import '../../domain/entities/business.dart';
import '../models/model.dart';
import 'dart:convert';

/// Модель шаблона согласования
class ApprovalTemplateModel extends ApprovalTemplate implements Model {
  const ApprovalTemplateModel({
    required super.id,
    required super.businessId,
    required super.code,
    required super.name,
    super.description,
    super.category,
    super.formSchema,
    super.workflowType,
    super.workflowConfig,
    super.finalApproverRole,
    super.executorDepartment,
    super.executorAction,
    super.isActive,
    required super.steps,
    required super.createdAt,
    required super.updatedAt,
    super.business,
  });

  factory ApprovalTemplateModel.fromJson(Map<String, dynamic> json) {
    Business? business;
    if (json['business'] != null) {
      final businessJson = json['business'] as Map<String, dynamic>;
      business = Business(
        id: businessJson['id'] as String,
        name: businessJson['name'] as String,
      );
    }

    List<ApprovalStep> steps = [];
    if (json['steps'] != null) {
      final stepsList = json['steps'] as List<dynamic>;
      steps = stepsList.map((stepJson) {
        return ApprovalStep(
          order: stepJson['order'] as int,
          type: _parseStepType(stepJson['type'] as String),
          departmentId: stepJson['departmentId'] as String?,
          userId: stepJson['userId'] as String?,
          isRequired: stepJson['isRequired'] as bool? ?? true,
        );
      }).toList();
    }

    // Парсинг formSchema
    Map<String, dynamic>? formSchema;
    if (json['formSchema'] != null) {
      if (json['formSchema'] is Map) {
        formSchema = json['formSchema'] as Map<String, dynamic>;
      } else if (json['formSchema'] is String) {
        try {
          formSchema = jsonDecode(json['formSchema'] as String) as Map<String, dynamic>;
        } catch (e) {
          // Если не удалось распарсить, оставляем null
        }
      }
    }

    // Парсинг workflowConfig
    Map<String, dynamic>? workflowConfig;
    if (json['workflowConfig'] != null) {
      if (json['workflowConfig'] is Map) {
        workflowConfig = json['workflowConfig'] as Map<String, dynamic>;
      } else if (json['workflowConfig'] is String) {
        try {
          workflowConfig = jsonDecode(json['workflowConfig'] as String) as Map<String, dynamic>;
        } catch (e) {
          // Если не удалось распарсить, оставляем null
        }
      }
    }

    return ApprovalTemplateModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String? ?? '',
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] != null
          ? _parseCategory(json['category'] as String)
          : null,
      formSchema: formSchema,
      workflowType: json['workflowType'] != null
          ? _parseWorkflowType(json['workflowType'] as String)
          : null,
      workflowConfig: workflowConfig,
      finalApproverRole: json['finalApproverRole'] as String?,
      executorDepartment: json['executorDepartment'] as String?,
      executorAction: json['executorAction'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      steps: steps,
      // В списках согласований сервер может отдавать "короткий" template без createdAt/updatedAt.
      // В этом случае используем дефолтные значения, чтобы не падать на парсинге.
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      business: business,
    );
  }

  static ApprovalTemplateCategory? _parseCategory(String category) {
    switch (category.toUpperCase()) {
      case 'FINANCIAL':
        return ApprovalTemplateCategory.financial;
      case 'HR':
        return ApprovalTemplateCategory.hr;
      case 'DOCUMENT':
        return ApprovalTemplateCategory.document;
      case 'OTHER':
        return ApprovalTemplateCategory.other;
      default:
        return null;
    }
  }

  static WorkflowType? _parseWorkflowType(String type) {
    switch (type.toUpperCase()) {
      case 'SEQUENTIAL':
        return WorkflowType.sequential;
      case 'PARALLEL':
        return WorkflowType.parallel;
      case 'CONDITIONAL':
        return WorkflowType.conditional;
      default:
        return null;
    }
  }

  static ApprovalStepType _parseStepType(String type) {
    switch (type.toUpperCase()) {
      case 'USER':
        return ApprovalStepType.user;
      case 'DEPARTMENT':
        return ApprovalStepType.department;
      case 'MANAGER':
        return ApprovalStepType.manager;
      default:
        return ApprovalStepType.user;
    }
  }

  static String _stepTypeToString(ApprovalStepType type) {
    switch (type) {
      case ApprovalStepType.user:
        return 'USER';
      case ApprovalStepType.department:
        return 'DEPARTMENT';
      case ApprovalStepType.manager:
        return 'MANAGER';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'code': code,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': _categoryToString(category!),
      if (formSchema != null) 'formSchema': formSchema,
      if (workflowType != null) 'workflowType': _workflowTypeToString(workflowType!),
      if (workflowConfig != null) 'workflowConfig': workflowConfig,
      if (finalApproverRole != null) 'finalApproverRole': finalApproverRole,
      if (executorDepartment != null) 'executorDepartment': executorDepartment,
      if (executorAction != null) 'executorAction': executorAction,
      'isActive': isActive,
      'steps': steps.map((step) => {
        'order': step.order,
        'type': _stepTypeToString(step.type),
        if (step.departmentId != null) 'departmentId': step.departmentId,
        if (step.userId != null) 'userId': step.userId,
        'isRequired': step.isRequired,
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static String _categoryToString(ApprovalTemplateCategory category) {
    switch (category) {
      case ApprovalTemplateCategory.financial:
        return 'FINANCIAL';
      case ApprovalTemplateCategory.hr:
        return 'HR';
      case ApprovalTemplateCategory.document:
        return 'DOCUMENT';
      case ApprovalTemplateCategory.other:
        return 'OTHER';
    }
  }

  static String _workflowTypeToString(WorkflowType type) {
    switch (type) {
      case WorkflowType.sequential:
        return 'SEQUENTIAL';
      case WorkflowType.parallel:
        return 'PARALLEL';
      case WorkflowType.conditional:
        return 'CONDITIONAL';
    }
  }

  ApprovalTemplate toEntity() {
    return ApprovalTemplate(
      id: id,
      businessId: businessId,
      code: code,
      name: name,
      description: description,
      category: category,
      formSchema: formSchema,
      workflowType: workflowType,
      workflowConfig: workflowConfig,
      finalApproverRole: finalApproverRole,
      executorDepartment: executorDepartment,
      executorAction: executorAction,
      isActive: isActive,
      steps: steps,
      createdAt: createdAt,
      updatedAt: updatedAt,
      business: business,
    );
  }

  factory ApprovalTemplateModel.fromEntity(ApprovalTemplate template) {
    return ApprovalTemplateModel(
      id: template.id,
      businessId: template.businessId,
      code: template.code,
      name: template.name,
      description: template.description,
      category: template.category,
      formSchema: template.formSchema,
      workflowType: template.workflowType,
      workflowConfig: template.workflowConfig,
      finalApproverRole: template.finalApproverRole,
      executorDepartment: template.executorDepartment,
      executorAction: template.executorAction,
      isActive: template.isActive,
      steps: template.steps,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      business: template.business,
    );
  }
}

