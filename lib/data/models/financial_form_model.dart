import '../../core/utils/json_utils.dart';
import '../../domain/entities/approval_template.dart';
import '../models/model.dart';
import '../models/approval_template_model.dart';

/// Модель финансовой формы
class FinancialFormModel implements Model {
  final ApprovalTemplateModel template;
  final Map<String, dynamic> formSchema;

  const FinancialFormModel({required this.template, required this.formSchema});

  factory FinancialFormModel.fromJson(Map<String, dynamic> json) {
    final templateJson = JsonUtils.mapOrEmpty(json['template']);
    final formSchemaJson = JsonUtils.mapOrEmpty(json['formSchema']);

    // Если template отсутствует, создаем минимальный template из formSchema
    if (templateJson.isEmpty || formSchemaJson.isEmpty) {
      // Создаем минимальный template, если его нет
      final minimalTemplate = ApprovalTemplateModel(
        id: '',
        businessId: '',
        code: 'income',
        name: 'Приход',
        formSchema: formSchemaJson,
        steps: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return FinancialFormModel(
        template: minimalTemplate,
        formSchema: formSchemaJson,
      );
    }

    // Объединяем formSchema из ответа с шаблоном
    // Создаем новый template с обновленным formSchema
    final templateModel = ApprovalTemplateModel.fromJson(templateJson);

    // Обновляем formSchema в шаблоне, добавляя опции из ответа
    final updatedFormSchema = Map<String, dynamic>.from(formSchemaJson);

    // Создаем новый template с обновленным formSchema
    final updatedTemplate = ApprovalTemplateModel(
      id: templateModel.id,
      businessId: templateModel.businessId,
      code: templateModel.code,
      name: templateModel.name,
      description: templateModel.description,
      category: templateModel.category,
      formSchema: updatedFormSchema,
      workflowType: templateModel.workflowType,
      workflowConfig: templateModel.workflowConfig,
      finalApproverRole: templateModel.finalApproverRole,
      executorDepartment: templateModel.executorDepartment,
      executorAction: templateModel.executorAction,
      isActive: templateModel.isActive,
      steps: templateModel.steps,
      createdAt: templateModel.createdAt,
      updatedAt: templateModel.updatedAt,
      business: templateModel.business,
    );

    return FinancialFormModel(
      template: updatedTemplate,
      formSchema: updatedFormSchema,
    );
  }

  /// Преобразует модель в ApprovalTemplate для использования в домене
  ApprovalTemplate toApprovalTemplate() {
    return template.toEntity();
  }

  @override
  Map<String, dynamic> toJson() {
    return {'template': template.toJson(), 'formSchema': formSchema};
  }
}
