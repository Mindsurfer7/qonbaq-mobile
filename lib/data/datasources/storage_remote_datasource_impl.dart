import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import '../../core/utils/token_storage.dart';
import '../datasources/storage_remote_datasource.dart';
import '../models/storage_upload_response.dart';
import '../models/storage_url_response.dart';
import '../models/api_response.dart';

/// Реализация удаленного источника данных для storage
class StorageRemoteDataSourceImpl extends StorageRemoteDataSource {
  final ApiClient apiClient;

  StorageRemoteDataSourceImpl({required this.apiClient});

  Map<String, String> _getAuthHeaders() {
    final token = TokenStorage.instance.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Токен авторизации не найден');
    }
    return {'Authorization': 'Bearer $token'};
  }

  @override
  Future<StorageUploadResponse> uploadFile({
    String? file,
    List<int>? fileBytes,
    required String fileName,
    required String module,
  }) async {
    try {
      final token = TokenStorage.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('Токен авторизации не найден');
      }

      final uri = Uri.parse(
        '${apiClient.baseUrl}/api/storage/upload?module=$module',
      );

      // Создаем multipart запрос
      final request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки
      request.headers.addAll(_getAuthHeaders());

      // Добавляем файл
      if (kIsWeb && fileBytes != null) {
        // Для веба используем байты
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
      } else if (!kIsWeb && file != null) {
        // Для мобильных платформ используем файл
        final fileObj = File(file);
        final fileSize = await fileObj.length();

        // Проверяем размер файла в зависимости от модуля
        final maxSize = _getMaxSizeForModule(module);
        if (fileSize > maxSize) {
          throw Exception(
            'Файл слишком большой. Максимум: ${(maxSize / 1024 / 1024).toStringAsFixed(1)} МБ',
          );
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            fileObj.path,
            filename: fileName,
          ),
        );
      } else {
        throw Exception('Не указан файл для загрузки');
      }

      // Отправляем запрос с таймаутом
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            'Таймаут загрузки файла. Проверьте подключение к интернету.',
          );
        },
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) =>
              StorageUploadResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (streamedResponse.statusCode == 400) {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final error = json['error'] as String? ?? 'Ошибка валидации файла';
        throw Exception(error);
      } else if (streamedResponse.statusCode == 401) {
        throw Exception('Не авторизован');
      } else {
        final json = jsonDecode(responseBody) as Map<String, dynamic>;
        final error =
            json['error'] as String? ??
            json['message'] as String? ??
            'Ошибка при загрузке файла';
        throw Exception(error);
      }
    } catch (e) {
      // Обработка специфичных ошибок для веба
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cors') ||
          errorString.contains('network') ||
          errorString.contains('failed to fetch') ||
          errorString.contains('networkerror')) {
        throw Exception(
          'Ошибка сети. Проверьте подключение к интернету и настройки CORS на сервере.',
        );
      } else if (errorString.contains('timeout')) {
        throw Exception(
          'Таймаут загрузки файла. Файл слишком большой или медленное соединение.',
        );
      }

      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<StorageUrlResponse> getFileUrl({
    required String fileId,
    required String module,
    int expiresIn = 3600,
    String? extension,
  }) async {
    try {
      final queryParams = <String, String>{
        'module': module,
        'expiresIn': expiresIn.toString(),
      };
      if (extension != null) {
        queryParams['extension'] = extension;
      }

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await apiClient.get(
        '/api/storage/$fileId/url?$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => StorageUrlResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = json['error'] as String? ?? 'Ошибка получения URL файла';
        throw Exception(error);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Файл не найден');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error =
            json['error'] as String? ??
            json['message'] as String? ??
            'Ошибка при получении URL файла';
        throw Exception(error);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  @override
  Future<StorageUrlResponse> getFileUrlByKey({
    required String key,
    required String bucket,
    int expiresIn = 3600,
  }) async {
    try {
      final queryParams = <String, String>{
        'bucket': bucket,
        'key': key,
        'expiresIn': expiresIn.toString(),
      };

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await apiClient.get(
        '/api/storage/url?$queryString',
        headers: _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final apiResponse = ApiResponse.fromJson(
          json,
          (data) => StorageUrlResponse.fromJson(data as Map<String, dynamic>),
        );
        return apiResponse.data;
      } else if (response.statusCode == 400) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = json['error'] as String? ?? 'Ошибка получения URL файла';
        throw Exception(error);
      } else if (response.statusCode == 401) {
        throw Exception('Не авторизован');
      } else if (response.statusCode == 404) {
        throw Exception('Файл не найден');
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error =
            json['error'] as String? ??
            json['message'] as String? ??
            'Ошибка при получении URL файла по ключу';
        throw Exception(error);
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Ошибка сети: $e');
    }
  }

  /// Получить максимальный размер файла для модуля (в байтах)
  int _getMaxSizeForModule(String module) {
    switch (module) {
      case 'attachments':
        return 10 * 1024 * 1024; // 10 МБ
      case 'assets':
      case 'receipts':
        return 5 * 1024 * 1024; // 5 МБ
      default:
        return 10 * 1024 * 1024; // По умолчанию 10 МБ
    }
  }
}
