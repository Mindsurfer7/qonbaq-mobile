import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/constants.dart';
import '../datasources/voice_assist_remote_datasource.dart';
import '../models/task_model.dart';
import '../models/api_response.dart';
import '../../domain/entities/task.dart';

/// Реализация удаленного источника данных для голосового ассистента
class VoiceAssistRemoteDataSourceImpl extends VoiceAssistRemoteDataSource {
  static const String _endpoint = '/api/voice-assist';

  @override
  Future<TaskModel> processVoiceMessage({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String context,
    String? templateCode,
    String? templateId,
  }) async {
    // Проверяем, что передан либо файл, либо байты
    if (audioFile == null && audioBytes == null) {
      throw Exception('Необходимо передать либо audioFile, либо audioBytes');
    }

    // Для веба используем байты, для остальных платформ - файл
    if (kIsWeb && audioBytes == null) {
      throw Exception('Для веб-платформы необходимы audioBytes');
    }

    if (!kIsWeb && audioFile == null) {
      throw Exception('Для не-веб платформ необходим audioFile');
    }

    // Валидация контекста
    if (context != 'task' && context != 'approval') {
      throw Exception('Контекст должен быть "task" или "approval"');
    }

    // Для approval обязательно нужен templateCode или templateId
    if (context == 'approval' && templateCode == null && templateId == null) {
      throw Exception('Для approval необходимо указать templateCode или templateId');
    }

    // Получаем токен авторизации
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }

    // Формируем URL с query параметрами
    final backendUrl = AppConstants.apiBaseUrl;
    final uri = Uri.parse('$backendUrl$_endpoint').replace(
      queryParameters: {
        'context': context,
        if (templateCode != null) 'templateCode': templateCode,
        if (templateId != null) 'templateId': templateId,
      },
    );

    try {
      // Создаем multipart запрос
      final request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Добавляем аудиофайл
      if (kIsWeb && audioBytes != null) {
        // Для веба используем байты
        request.files.add(
          http.MultipartFile.fromBytes('file', audioBytes, filename: filename),
        );
      } else if (!kIsWeb && audioFile != null) {
        // Для не-веб платформ используем файл
        final file = File(audioFile);
        final fileSize = await file.length();
        
        // Проверяем размер файла (максимум 25 МБ)
        const maxSizeInBytes = 25 * 1024 * 1024; // 25 МБ
        if (fileSize > maxSizeInBytes) {
          throw Exception('Файл слишком большой. Максимум: 25 МБ');
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: filename,
          ),
        );
      }

      // Отправляем запрос
      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        // Парсим ответ используя ApiResponse
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        
        final apiResponse = ApiResponse.fromJson(
          json,
          (dataJson) {
            // Парсим данные задачи из ответа
            // Endpoint возвращает только поля задачи без связей (assignedTo, assignedBy - это ID строки)
            // Нужно создать TaskModel с частичными данными
            final taskJson = dataJson as Map<String, dynamic>;
            
            // Создаем минимальный TaskModel с предзаполненными данными
            // Для полей, которых нет в ответе, используем значения по умолчанию
            return TaskModel(
              id: '', // Будет присвоен при создании
              businessId: taskJson['businessId'] as String? ?? '',
              title: taskJson['title'] as String? ?? '',
              description: taskJson['description'] as String?,
              status: _parseStatus(taskJson['status'] as String?),
              priority: _parsePriority(taskJson['priority'] as String?),
              assignedTo: taskJson['assignedTo'] as String?,
              assignedBy: taskJson['assignedBy'] as String?,
              assignmentDate: taskJson['assignmentDate'] != null
                  ? DateTime.parse(taskJson['assignmentDate'] as String)
                  : null,
              deadline: taskJson['deadline'] != null
                  ? DateTime.parse(taskJson['deadline'] as String)
                  : null,
              isImportant: taskJson['isImportant'] as bool? ?? false,
              isRecurring: taskJson['isRecurring'] as bool? ?? false,
              hasControlPoint: taskJson['hasControlPoint'] as bool? ?? false,
              dontForget: taskJson['dontForget'] as bool? ?? false,
              voiceNoteUrl: taskJson['voiceNoteUrl'] as String?,
              createdAt: DateTime.now(), // Временное значение
              updatedAt: DateTime.now(), // Временное значение
              observerIds: taskJson['observerIds'] != null
                  ? List<String>.from(taskJson['observerIds'] as List)
                  : null,
            );
          },
        );

        return apiResponse.data;
      } else {
        // Обрабатываем ошибки через ErrorHandler
        String userMessage = ErrorHandler.getErrorMessage(
          streamedResponse.statusCode,
          responseBody,
        );
        throw Exception(userMessage);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('Ошибка при отправке аудио для обработки: $e');
      }
    }
  }

  /// Парсит статус задачи из строки
  static TaskStatus _parseStatus(String? status) {
    if (status == null) return TaskStatus.pending;
    switch (status.toUpperCase()) {
      case 'PENDING':
        return TaskStatus.pending;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'CANCELLED':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  /// Парсит приоритет задачи из строки
  static TaskPriority? _parsePriority(String? priority) {
    if (priority == null) return null;
    switch (priority.toUpperCase()) {
      case 'LOW':
        return TaskPriority.low;
      case 'MEDIUM':
        return TaskPriority.medium;
      case 'HIGH':
        return TaskPriority.high;
      case 'URGENT':
        return TaskPriority.urgent;
      default:
        return null;
    }
  }
}

