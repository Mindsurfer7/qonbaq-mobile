import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/utils/token_storage.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/constants.dart';
import '../datasources/transcription_remote_datasource.dart';
import '../models/transcription_response.dart';

/// Реализация удаленного источника данных для транскрипции
class TranscriptionRemoteDataSourceImpl extends TranscriptionRemoteDataSource {
  static const String _endpoint = '/api/transcribe';

  @override
  Future<TranscriptionResponse> transcribeAudio({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
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

    // Получаем токен авторизации
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }

    // Формируем URL
    final backendUrl = AppConstants.apiBaseUrl;
    final url = Uri.parse('$backendUrl$_endpoint');

    try {
      // Создаем multipart запрос
      final request = http.MultipartRequest('POST', url);

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
        // Парсим ответ
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        // Сервер возвращает ответ в формате { "data": { "text": "...", "metadata": {...} } }
        if (!json.containsKey('data')) {
          throw Exception('Неожиданный формат ответа: отсутствует поле "data"');
        }

        final data = json['data'] as Map<String, dynamic>;
        final transcriptionResponse = TranscriptionResponse.fromJson(data);

        // Проверяем, что текст не пустой
        if (transcriptionResponse.text.isEmpty) {
          throw Exception('Сервер вернул пустой текст транскрипции');
        }

        return transcriptionResponse;
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
        throw Exception('Ошибка при отправке аудио для транскрипции: $e');
      }
    }
  }

  /// Проверяет, поддерживается ли формат файла
  static bool isSupportedFormat(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return ['mp3', 'webm', 'ogg', 'wav', 'm4a'].contains(extension);
  }

  /// Проверяет размер файла (максимум 25 МБ)
  static bool isValidFileSize(int sizeInBytes) {
    const maxSizeInBytes = 25 * 1024 * 1024; // 25 МБ
    return sizeInBytes <= maxSizeInBytes;
  }
}
