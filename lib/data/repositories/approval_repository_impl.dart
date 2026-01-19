import 'package:dartz/dartz.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/approval_attachment.dart';
import '../../domain/entities/approval_decision.dart';
import '../../domain/entities/pending_confirmation.dart';
import '../../domain/entities/templates_result.dart';
import '../../domain/entities/approvals_result.dart';
import '../../domain/entities/missing_role_info.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../core/error/failures.dart';
import '../models/approval_model.dart';
import '../models/approval_template_model.dart';
import '../datasources/approval_remote_datasource.dart';
import '../datasources/approval_remote_datasource_impl.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория согласований
class ApprovalRepositoryImpl extends RepositoryImpl implements ApprovalRepository {
  final ApprovalRemoteDataSource remoteDataSource;

  ApprovalRepositoryImpl({
    required this.remoteDataSource,
  });

  // Шаблоны согласований
  @override
  Future<Either<Failure, ApprovalTemplate>> createTemplate(ApprovalTemplate template) async {
    try {
      final templateModel = ApprovalTemplateModel.fromEntity(template);
      final createdTemplate = await remoteDataSource.createTemplate(templateModel);
      return Right(createdTemplate.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании шаблона: $e'));
    }
  }

  @override
  Future<Either<Failure, TemplatesResult>> getTemplates({String? businessId}) async {
    try {
      final result = await remoteDataSource.getTemplates(businessId: businessId);
      final templates = result.data.map((model) => model.toEntity()).toList();
      
      // Преобразуем метаданные из data слоя в domain entities
      List<MissingRoleInfo>? missingRoles;
      if (result.meta?.missingRoles != null) {
        missingRoles = result.meta!.missingRoles!.map((role) {
          return MissingRoleInfo(
            roleCode: role.roleCode,
            roleName: role.roleName,
            affectedTemplates: role.affectedTemplates.map((template) {
              return AffectedTemplateInfo(
                id: template.id,
                name: template.name,
                code: template.code,
              );
            }).toList(),
          );
        }).toList();
      }
      
      return Right(TemplatesResult(
        templates: templates,
        missingRoles: missingRoles,
        totalMissing: result.meta?.totalMissing,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении шаблонов: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalTemplate>> getTemplateById(String templateId) async {
    try {
      final template = await remoteDataSource.getTemplateById(templateId);
      return Right(template.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении шаблона: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalTemplate>> getTemplateByCode(
    String code, {
    String? businessId,
  }) async {
    try {
      final template = await remoteDataSource.getTemplateByCode(
        code,
        businessId: businessId,
      );
      return Right(template.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении шаблона: $e'));
    }
  }

  // Согласования
  @override
  Future<Either<Failure, Approval>> createApproval(Approval approval) async {
    try {
      final approvalModel = ApprovalModel.fromEntity(approval);
      final createdApproval = await remoteDataSource.createApproval(approvalModel);
      return Right(createdApproval.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании согласования: $e'));
    }
  }

  @override
  Future<Either<Failure, Approval>> updateApproval(
    String id, {
    String? title,
    String? projectId,
    double? amount,
    Map<String, dynamic>? formData,
  }) async {
    try {
      final updatedApproval = await remoteDataSource.updateApproval(
        id,
        title: title,
        projectId: projectId,
        amount: amount,
        formData: formData,
      );
      return Right(updatedApproval.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении согласования: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalsResult>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove,
    bool? showAll,
    int? page,
    int? limit,
  }) async {
    try {
      final result = await remoteDataSource.getApprovals(
        businessId: businessId,
        status: status,
        createdBy: createdBy,
        canApprove: canApprove,
        showAll: showAll,
        page: page,
        limit: limit,
      );
      
      final approvals = result.data.map((model) => model.toEntity()).toList();
      
      // Преобразуем метаданные из data слоя в domain entities
      List<UnassignedRoleInfo>? unassignedRoles;
      if (result.meta?.unassignedRoles != null) {
        unassignedRoles = result.meta!.unassignedRoles!.map((role) {
          return UnassignedRoleInfo(
            code: role.code,
            name: role.name,
          );
        }).toList();
      }
      
      return Right(ApprovalsResult(
        approvals: approvals,
        unassignedRoles: unassignedRoles,
        message: result.meta?.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении согласований: $e'));
    }
  }

  @override
  Future<Either<Failure, Approval>> getApprovalById(String id) async {
    try {
      final approval = await remoteDataSource.getApprovalById(id);
      return Right(approval.toEntity());
    } on ForbiddenException catch (e) {
      return Left(ForbiddenFailure(e.message));
    } on Exception catch (e) {
      // Используем сообщение из Exception напрямую (оно уже парсится из error в body)
      return Left(ServerFailure(e.toString()));
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении согласования: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalDecision>> decideApproval(
    String id,
    ApprovalDecisionType decision,
    String? comment,
    String? executorId,
  ) async {
    try {
      final decisionModel = await remoteDataSource.decideApproval(id, decision, comment, executorId);
      return Right(decisionModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при принятии решения: $e'));
    }
  }

  // Комментарии
  @override
  Future<Either<Failure, ApprovalComment>> createComment(String approvalId, String text) async {
    try {
      final comment = await remoteDataSource.createComment(approvalId, text);
      return Right(comment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании комментария: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ApprovalComment>>> getComments(String approvalId) async {
    try {
      final comments = await remoteDataSource.getComments(approvalId);
      return Right(comments.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении комментариев: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalComment>> updateComment(
    String approvalId,
    String commentId,
    String text,
  ) async {
    try {
      final comment = await remoteDataSource.updateComment(approvalId, commentId, text);
      return Right(comment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при обновлении комментария: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(String approvalId, String commentId) async {
    try {
      await remoteDataSource.deleteComment(approvalId, commentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении комментария: $e'));
    }
  }

  // Вложения
  @override
  Future<Either<Failure, ApprovalAttachment>> addAttachment(
    String approvalId,
    String fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  ) async {
    try {
      final attachment = await remoteDataSource.addAttachment(
        approvalId,
        fileUrl,
        fileName,
        fileType,
        fileSize,
      );
      return Right(attachment.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при добавлении вложения: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ApprovalAttachment>>> getAttachments(String approvalId) async {
    try {
      final attachments = await remoteDataSource.getAttachments(approvalId);
      return Right(attachments.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении вложений: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAttachment(String approvalId, String attachmentId) async {
    try {
      await remoteDataSource.deleteAttachment(approvalId, attachmentId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Ошибка при удалении вложения: $e'));
    }
  }

  // Подтверждения
  @override
  Future<Either<Failure, List<PendingConfirmation>>> getPendingConfirmations({String? businessId}) async {
    try {
      final confirmations = await remoteDataSource.getPendingConfirmations(businessId: businessId);
      return Right(confirmations.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении pending confirmations: $e'));
    }
  }

  @override
  Future<Either<Failure, Approval>> confirmApproval(
    String id, {
    required bool isConfirmed,
    double? amount,
    String? comment,
  }) async {
    try {
      final approval = await remoteDataSource.confirmApproval(
        id,
        isConfirmed: isConfirmed,
        amount: amount,
        comment: comment,
      );
      return Right(approval.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        e.validationResponse.message ?? e.validationResponse.error,
        e.validationResponse.details,
        serverMessage: e.validationResponse.message,
      ));
    } catch (e) {
      return Left(ServerFailure('Ошибка при подтверждении согласования: $e'));
    }
  }
}

