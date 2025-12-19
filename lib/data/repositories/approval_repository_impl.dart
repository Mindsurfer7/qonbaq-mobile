import 'package:dartz/dartz.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/approval_attachment.dart';
import '../../domain/entities/approval_decision.dart';
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
  Future<Either<Failure, List<ApprovalTemplate>>> getTemplates({String? businessId}) async {
    try {
      final templates = await remoteDataSource.getTemplates(businessId: businessId);
      return Right(templates.map((model) => model.toEntity()).toList());
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
  Future<Either<Failure, ApprovalTemplate>> getTemplateByCode(String code) async {
    try {
      final template = await remoteDataSource.getTemplateByCode(code);
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
  Future<Either<Failure, List<Approval>>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove,
    int? page,
    int? limit,
  }) async {
    try {
      final approvals = await remoteDataSource.getApprovals(
        businessId: businessId,
        status: status,
        createdBy: createdBy,
        canApprove: canApprove,
        page: page,
        limit: limit,
      );
      return Right(approvals.map((model) => model.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении согласований: $e'));
    }
  }

  @override
  Future<Either<Failure, Approval>> getApprovalById(String id) async {
    try {
      final approval = await remoteDataSource.getApprovalById(id);
      return Right(approval.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении согласования: $e'));
    }
  }

  @override
  Future<Either<Failure, ApprovalDecision>> decideApproval(
    String id,
    ApprovalDecisionType decision,
    String? comment,
  ) async {
    try {
      final decisionModel = await remoteDataSource.decideApproval(id, decision, comment);
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
}

