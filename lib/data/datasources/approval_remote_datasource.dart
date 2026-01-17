import '../datasources/datasource.dart';
import '../models/api_response.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_decision.dart';
import '../models/approval_model.dart';
import '../models/approval_template_model.dart';
import '../models/approval_comment_model.dart';
import '../models/approval_attachment_model.dart';
import '../models/approval_decision_model.dart';
import '../models/pending_confirmation_model.dart';

/// Удаленный источник данных для согласований (API)
abstract class ApprovalRemoteDataSource extends DataSource {
  // Шаблоны согласований
  /// Создать шаблон
  Future<ApprovalTemplateModel> createTemplate(ApprovalTemplateModel template);

  /// Получить список шаблонов с метаданными
  Future<ApiResponse<List<ApprovalTemplateModel>>> getTemplates({String? businessId});

  /// Получить шаблон по ID
  Future<ApprovalTemplateModel> getTemplateById(String templateId);

  /// Получить шаблон по коду
  Future<ApprovalTemplateModel> getTemplateByCode(String code);

  // Согласования
  /// Создать согласование
  Future<ApprovalModel> createApproval(ApprovalModel approval);

  /// Обновить согласование
  Future<ApprovalModel> updateApproval(
    String id, {
    String? title,
    String? projectId,
    double? amount,
    Map<String, dynamic>? formData,
  });

  /// Получить список согласований
  Future<ApiResponse<List<ApprovalModel>>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove, // Если true, возвращает только те, которые пользователь может одобрить
    bool? showAll, // Если true, возвращает все согласования в бизнесе (только для привилегированных)
    int? page,
    int? limit,
  });

  /// Получить согласование по ID
  Future<ApprovalModel> getApprovalById(String id);

  /// Принять решение по согласованию
  Future<ApprovalDecisionModel> decideApproval(
    String id,
    ApprovalDecisionType decision,
    String? comment,
    String? executorId,
  );

  // Комментарии
  /// Создать комментарий
  Future<ApprovalCommentModel> createComment(String approvalId, String text);

  /// Получить список комментариев
  Future<List<ApprovalCommentModel>> getComments(String approvalId);

  /// Обновить комментарий
  Future<ApprovalCommentModel> updateComment(
    String approvalId,
    String commentId,
    String text,
  );

  /// Удалить комментарий
  Future<void> deleteComment(String approvalId, String commentId);

  // Вложения
  /// Добавить вложение
  Future<ApprovalAttachmentModel> addAttachment(
    String approvalId,
    String fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  );

  /// Получить список вложений
  Future<List<ApprovalAttachmentModel>> getAttachments(String approvalId);

  /// Удалить вложение
  Future<void> deleteAttachment(String approvalId, String attachmentId);

  // Подтверждения
  /// Получить список согласований, требующих подтверждения
  Future<List<PendingConfirmationModel>> getPendingConfirmations({String? businessId});

  /// Подтвердить согласование
  Future<ApprovalModel> confirmApproval(
    String id, {
    required bool isConfirmed,
    double? amount,
    String? comment,
  });
}

