import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_decision.dart';
import '../datasources/approval_remote_datasource.dart';
import '../models/approval_model.dart';
import '../models/approval_template_model.dart';
import '../models/approval_comment_model.dart';
import '../models/approval_attachment_model.dart';
import '../models/approval_decision_model.dart';
import '../models/validation_error.dart';

/// Реализация удаленного источника данных для согласований
class ApprovalRemoteDataSourceImpl extends ApprovalRemoteDataSource {
  final ApiClient apiClient;

  ApprovalRemoteDataSourceImpl({required this.apiClient});

  Map<String, String> _getAuthHeaders() {
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Шаблоны согласований
  @override
  Future<ApprovalTemplateModel> createTemplate(
    ApprovalTemplateModel template,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/approvals/templates',
        headers: _getAuthHeaders(),
        body: template.toJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApprovalTemplateModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<ApprovalTemplateModel>> getTemplates({String? businessId}) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) queryParams['businessId'] = businessId;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/approvals/templates$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final templatesList =
            json['templates'] as List<dynamic>? ??
            json['data'] as List<dynamic>? ??
            [];
        return templatesList
            .map(
              (item) =>
                  ApprovalTemplateModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ApprovalTemplateModel> getTemplateById(String templateId) async {
    try {
      final response = await apiClient.get(
        '/api/approvals/templates/$templateId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApprovalTemplateModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Шаблон не найден');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ApprovalTemplateModel> getTemplateByCode(String code) async {
    try {
      final response = await apiClient.get(
        '/api/approvals/templates/code/$code',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApprovalTemplateModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Шаблон не найден');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  // Согласования
  @override
  Future<ApprovalModel> createApproval(ApprovalModel approval) async {
    try {
      final response = await apiClient.post(
        '/api/approvals',
        headers: _getAuthHeaders(),
        body: approval.toCreateJson(),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Сервер возвращает объект с полем "approval"
        final approvalJson = json['approval'] as Map<String, dynamic>? ?? json;
        return ApprovalModel.fromJson(approvalJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<ApprovalModel>> getApprovals({
    String? businessId,
    ApprovalStatus? status,
    String? createdBy,
    bool? canApprove,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) queryParams['businessId'] = businessId;
      if (status != null) queryParams['status'] = _statusToString(status);
      if (createdBy != null) queryParams['createdBy'] = createdBy;
      if (canApprove != null) queryParams['canApprove'] = canApprove.toString();
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

      final response = await apiClient.get(
        '/api/approvals$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final approvalsList =
            json['approvals'] as List<dynamic>? ??
            json['data'] as List<dynamic>? ??
            [];
        return approvalsList
            .map((item) => ApprovalModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ApprovalModel> getApprovalById(String id) async {
    try {
      final response = await apiClient.get(
        '/api/approvals/$id',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Сервер может вернуть объект-обёртку { "approval": { ... } }
        final approvalJson = json['approval'] as Map<String, dynamic>? ?? json;
        return ApprovalModel.fromJson(approvalJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ApprovalDecisionModel> decideApproval(
    String id,
    ApprovalDecisionType decision,
    String? comment,
  ) async {
    try {
      final body = <String, dynamic>{'decision': _decisionToString(decision)};
      if (comment != null && comment.isNotEmpty) {
        body['comment'] = comment;
      }

      final response = await apiClient.post(
        '/api/approvals/$id/decide',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApprovalDecisionModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  // Комментарии
  @override
  Future<ApprovalCommentModel> createComment(
    String approvalId,
    String text,
  ) async {
    try {
      final response = await apiClient.post(
        '/api/approvals/$approvalId/comments',
        headers: _getAuthHeaders(),
        body: {'text': text},
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Сервер может вернуть объект-обёртку { "comment": { ... } }
        final commentJson = json['comment'] as Map<String, dynamic>? ?? json;
        return ApprovalCommentModel.fromJson(commentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<ApprovalCommentModel>> getComments(String approvalId) async {
    try {
      final response = await apiClient.get(
        '/api/approvals/$approvalId/comments',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final commentsList =
            json['comments'] as List<dynamic>? ??
            json['data'] as List<dynamic>? ??
            [];
        return commentsList
            .map(
              (item) =>
                  ApprovalCommentModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ApprovalCommentModel> updateComment(
    String approvalId,
    String commentId,
    String text,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/approvals/$approvalId/comments/$commentId',
        headers: _getAuthHeaders(),
        body: {'text': text},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // Сервер может вернуть объект-обёртку { "comment": { ... } }
        final commentJson = json['comment'] as Map<String, dynamic>? ?? json;
        return ApprovalCommentModel.fromJson(commentJson);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Комментарий не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<void> deleteComment(String approvalId, String commentId) async {
    try {
      final response = await apiClient.delete(
        '/api/approvals/$approvalId/comments/$commentId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Комментарий не найден');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  // Вложения
  @override
  Future<ApprovalAttachmentModel> addAttachment(
    String approvalId,
    String fileUrl,
    String? fileName,
    String? fileType,
    int? fileSize,
  ) async {
    try {
      final body = <String, dynamic>{'fileUrl': fileUrl};
      if (fileName != null) body['fileName'] = fileName;
      if (fileType != null) body['fileType'] = fileType;
      if (fileSize != null) body['fileSize'] = fileSize;

      final response = await apiClient.post(
        '/api/approvals/$approvalId/attachments',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ApprovalAttachmentModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ValidationException) {
        rethrow;
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<ApprovalAttachmentModel>> getAttachments(
    String approvalId,
  ) async {
    try {
      final response = await apiClient.get(
        '/api/approvals/$approvalId/attachments',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final attachmentsList =
            json['attachments'] as List<dynamic>? ??
            json['data'] as List<dynamic>? ??
            [];
        return attachmentsList
            .map(
              (item) => ApprovalAttachmentModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String approvalId, String attachmentId) async {
    try {
      final response = await apiClient.delete(
        '/api/approvals/$approvalId/attachments/$attachmentId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Вложение не найдено');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  String _statusToString(ApprovalStatus status) {
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

  String _decisionToString(ApprovalDecisionType decision) {
    switch (decision) {
      case ApprovalDecisionType.approved:
        return 'APPROVED';
      case ApprovalDecisionType.rejected:
        return 'REJECTED';
    }
  }
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() => validationResponse.message ?? validationResponse.error;
}
