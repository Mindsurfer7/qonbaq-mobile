import 'package:dartz/dartz.dart';
import '../entities/approval.dart';
import '../entities/approval_template.dart';
import '../entities/approval_comment.dart';
import '../entities/approval_attachment.dart';
import '../entities/approval_decision.dart';
import '../entities/pending_confirmation.dart';
import '../entities/templates_result.dart';
import '../entities/approvals_result.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с согласованиями
abstract class ApprovalRepository extends Repository {
  // Шаблоны согласований
  /// Создать шаблон
  Future<Either<Failure, ApprovalTemplate>> createTemplate(ApprovalTemplate template);

  /// Получить список шаблонов с метаданными
  Future<Either<Failure, TemplatesResult>> getTemplates({String? businessId});

  /// Получить шаблон по ID
  Future<Either<Failure, ApprovalTemplate>> getTemplateById(String templateId);

  /// Получить шаблон по коду
  Future<Either<Failure, ApprovalTemplate>> getTemplateByCode(
    String code, {
    String? businessId,
  });

  // Согласования
  /// Создать согласование
  Future<Either<Failure, Approval>> createApproval(Approval approval);

  /// Обновить согласование
  Future<Either<Failure, Approval>> updateApproval(
    String id, {
    String? title,
    String? projectId,
    double? amount,
    Map<String, dynamic>? formData,
  });

  /// Получить список согласований
  Future<Either<Failure, ApprovalsResult>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove,
    bool? showAll,
    int? page,
    int? limit,
  });

  /// Получить согласование по ID
  Future<Either<Failure, Approval>> getApprovalById(String id);

  /// Принять решение по согласованию
  Future<Either<Failure, ApprovalDecision>> decideApproval(
    String id,
    ApprovalDecisionType decision,
    String? comment,
    String? executorId,
  );

  // Комментарии
  /// Создать комментарий
  Future<Either<Failure, ApprovalComment>> createComment(String approvalId, String text);

  /// Получить список комментариев
  Future<Either<Failure, List<ApprovalComment>>> getComments(String approvalId);

  /// Обновить комментарий
  Future<Either<Failure, ApprovalComment>> updateComment(
    String approvalId,
    String commentId,
    String text,
  );

  /// Удалить комментарий
  Future<Either<Failure, void>> deleteComment(String approvalId, String commentId);

  // Вложения
  /// Добавить вложение
  Future<Either<Failure, ApprovalAttachment>> addAttachment(
    String approvalId,
    String fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  );

  /// Получить список вложений
  Future<Either<Failure, List<ApprovalAttachment>>> getAttachments(String approvalId);

  /// Удалить вложение
  Future<Either<Failure, void>> deleteAttachment(String approvalId, String attachmentId);

  // Подтверждения
  /// Получить список согласований, требующих подтверждения
  Future<Either<Failure, List<PendingConfirmation>>> getPendingConfirmations({String? businessId});

  /// Подтвердить согласование
  Future<Either<Failure, Approval>> confirmApproval(
    String id, {
    required bool isConfirmed,
    double? amount,
    String? comment,
  });

  /// Заполнить платежные реквизиты
  Future<Either<Failure, Approval>> fillPaymentDetails(
    String id, {
    required String paymentMethod,
    String? accountId,
    String? fromAccountId,
  });
}

