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
import '../models/api_response.dart';

/// Реализация удаленного источника данных для согласований
class ApprovalRemoteDataSourceImpl extends ApprovalRemoteDataSource {
  final ApiClient apiClient;

  ApprovalRemoteDataSourceImpl({required this.apiClient});

  /// Парсит сообщение об ошибке из body ответа
  /// Возвращает сообщение из поля 'error' или дефолтное сообщение
  String _parseErrorMessage(String body, String defaultMessage) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }

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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) =>
              ApprovalTemplateModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(json, (data) {
          final templatesList = data as List<dynamic>;
          return templatesList
              .map(
                (item) => ApprovalTemplateModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        });
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) =>
              ApprovalTemplateModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) =>
              ApprovalTemplateModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка сервера: ${response.statusCode}',
        );
        throw Exception(errorMessage);
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
  Future<ApprovalModel> updateApproval(
    String id, {
    String? title,
    String? projectId,
    double? amount,
    Map<String, dynamic>? formData,
  }) async {
    try {
      // Создаем временную модель для использования toUpdateJson
      final tempModel = ApprovalModel(
        id: id,
        businessId: projectId ?? '',
        title: title ?? '',
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        formData: formData,
      );
      
      final response = await apiClient.put(
        '/api/approvals/$id',
        headers: _getAuthHeaders(),
        body: tempModel.toUpdateJson(
          title: title,
          projectId: projectId,
          amount: amount,
          formData: formData,
        ),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 400) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Нельзя редактировать согласование',
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 403) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Нет прав на обновление',
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Согласование не найдено');
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Ошибка сервера: ${response.statusCode}',
        );
        throw Exception(errorMessage);
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
    bool? showAll,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (businessId != null) queryParams['businessId'] = businessId;
      if (status != null) queryParams['status'] = _statusToString(status);
      if (createdBy != null) queryParams['createdBy'] = createdBy;
      if (canApprove != null) queryParams['canApprove'] = canApprove.toString();
      if (showAll != null) queryParams['showAll'] = showAll.toString();
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
        final apiResponse = ApiResponse.fromJson(json, (data) {
          final approvalsList = data as List<dynamic>;
          return approvalsList
              .map(
                (item) => ApprovalModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        });
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Не авторизован',
        );
        throw Exception(errorMessage);
      } else if (response.statusCode == 403) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Нет доступа к этому согласованию',
        );
        throw ForbiddenException(errorMessage);
      } else if (response.statusCode == 404) {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Согласование не найдено',
        );
        throw Exception(errorMessage);
      } else {
        final errorMessage = _parseErrorMessage(
          response.body,
          'Произошла ошибка при загрузке согласования',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is ForbiddenException) {
        rethrow;
      }
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalModel.fromJson(data as Map<String, dynamic>),
        );
        final approval = apiResponse.data;
        
        // API возвращает полный объект Approval, нужно извлечь последнее решение
        if (approval.decisions != null && approval.decisions!.isNotEmpty) {
          // Берем последнее решение (самое свежее)
          final lastDecision = approval.decisions!.last;
          // Преобразуем в модель - решение уже парсится в ApprovalModel
          return ApprovalDecisionModel(
            id: lastDecision.id,
            approvalId: lastDecision.approvalId,
            decision: lastDecision.decision,
            comment: lastDecision.comment,
            userId: lastDecision.userId,
            createdAt: lastDecision.createdAt,
            user: lastDecision.user,
          );
        } else {
          // Если решений нет, но статус 200, значит решение принято успешно
          // Создаем фиктивное решение для обратной совместимости
          throw Exception('Решение не найдено в ответе сервера. Статус согласования: ${approval.status}');
        }
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalCommentModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(json, (data) {
          final commentsList = data as List<dynamic>;
          return commentsList
              .map(
                (item) =>
                    ApprovalCommentModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        });
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ApprovalCommentModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) =>
              ApprovalAttachmentModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
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
        final apiResponse = ApiResponse.fromJson(json, (data) {
          final attachmentsList = data as List<dynamic>;
          return attachmentsList
              .map(
                (item) => ApprovalAttachmentModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList();
        });
        return apiResponse.data;
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
        return 'APPROVE';
      case ApprovalDecisionType.rejected:
        return 'REJECT';
      case ApprovalDecisionType.requestChanges:
        return 'REQUEST_CHANGES';
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

/// Исключение для ошибок доступа (403 Forbidden)
class ForbiddenException implements Exception {
  final String message;

  ForbiddenException(this.message);

  @override
  String toString() => message;
}
