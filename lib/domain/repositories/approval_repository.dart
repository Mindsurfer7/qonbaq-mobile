import 'package:dartz/dartz.dart';
import '../entities/approval.dart';
import '../entities/approval_template.dart';
import '../entities/approval_comment.dart';
import '../entities/approval_attachment.dart';
import '../entities/approval_decision.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с согласованиями
abstract class ApprovalRepository extends Repository {
  // Шаблоны согласований
  /// Создать шаблон
  Future<Either<Failure, ApprovalTemplate>> createTemplate(ApprovalTemplate template);

  /// Получить список шаблонов
  Future<Either<Failure, List<ApprovalTemplate>>> getTemplates({String? businessId});

  /// Получить шаблон по ID
  Future<Either<Failure, ApprovalTemplate>> getTemplateById(String templateId);

  /// Получить шаблон по коду
  Future<Either<Failure, ApprovalTemplate>> getTemplateByCode(String code);

  // Согласования
  /// Создать согласование
  Future<Either<Failure, Approval>> createApproval(Approval approval);

  /// Получить список согласований
  Future<Either<Failure, List<Approval>>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove,
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
}

