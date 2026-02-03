import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/validation_error.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для чатов
class ChatRemoteDataSourceImpl extends ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

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

  @override
  Future<List<ChatModel>> getChats() async {
    try {
      final response = await apiClient.get(
        '/api/chats',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final chatsList = data as List<dynamic>;
            return chatsList
                .map((item) =>
                    ChatModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при получении списка чатов',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<ChatModel>> getAnonymousChats(
    String businessId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/chats/business/$businessId/anonymous-chats?page=$page&limit=$limit',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final chatsList = data as List<dynamic>;
            return chatsList
                .map((item) =>
                    ChatModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 403) {
        throw Exception('Нет доступа к этому бизнесу');
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при получении списка анонимных чатов',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  String _extractErrorMessage(String responseBody, String defaultMessage) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      return json['error'] as String? ?? 
          json['message'] as String? ?? 
          defaultMessage;
    } catch (_) {
      return defaultMessage;
    }
  }

  @override
  Future<ChatModel> getOrCreateChatWithUser(
    String userId, {
    String? currentUserId,
    String? currentUserName,
  }) async {
    try {
      final response = await apiClient.get(
        '/api/chats/with/$userId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ChatModel.fromJson(
            data as Map<String, dynamic>,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          ),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Пользователь не найден');
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при получении или создании чата с пользователем',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<ChatModel> getChatById(String chatId) async {
    try {
      final response = await apiClient.get(
        '/api/chats/$chatId',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => ChatModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Чат не найден');
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при получении чата',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<List<MessageModel>> getChatMessages(String chatId) async {
    try {
      final response = await apiClient.get(
        '/api/chats/$chatId/messages',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) {
            final messagesList = data as List<dynamic>;
            return messagesList
                .map((item) =>
                    MessageModel.fromJson(item as Map<String, dynamic>))
                .toList();
          },
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Чат не найден');
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при получении сообщений чата',
        );
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<MessageModel> sendMessage(
    String chatId,
    String text, {
    String? replyToMessageId,
    String? taskId,
    String? approvalId,
  }) async {
    try {
      final body = <String, dynamic>{
        'text': text,
      };
      if (replyToMessageId != null) {
        body['replyToMessageId'] = replyToMessageId;
      }
      if (taskId != null) {
        body['taskId'] = taskId;
      }
      if (approvalId != null) {
        body['approvalId'] = approvalId;
      }

      final response = await apiClient.post(
        '/api/chats/$chatId/messages',
        headers: _getAuthHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => MessageModel.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Чат не найден');
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final validationResponse = ValidationErrorResponse.fromJson(json);
        throw ValidationException(validationResponse);
      } else {
        final errorMessage = _extractErrorMessage(
          response.body,
          'Ошибка при отправке сообщения',
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
}

/// Исключение для ошибок валидации
class ValidationException implements Exception {
  final ValidationErrorResponse validationResponse;

  ValidationException(this.validationResponse);

  @override
  String toString() =>
      validationResponse.message ?? validationResponse.error;
}

