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
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 FILE UPLOAD START');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📋 File name: $fileName');
    print('📦 Module: $module');
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

    try {
      final token = TokenStorage.instance.getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ Token not found');
        throw Exception('Токен авторизации не найден');
      }
      print('✅ Token found (length: ${token.length})');

      final uri = Uri.parse(
        '${apiClient.baseUrl}/api/storage/upload?module=$module',
      );
      print('🔗 Upload URL: $uri');

      // Создаем multipart запрос
      final request = http.MultipartRequest('POST', uri);

      // Добавляем заголовки
      request.headers.addAll(_getAuthHeaders());
      print('📋 Request headers: ${request.headers.keys.toList()}');

      // Добавляем файл
      if (kIsWeb && fileBytes != null) {
        // Для веба используем байты
        print(
          '📦 File bytes size: ${fileBytes.length} bytes (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)',
        );
        request.files.add(
          http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
        );
        print('✅ MultipartFile created from bytes');
      } else if (!kIsWeb && file != null) {
        // Для мобильных платформ используем файл
        final fileObj = File(file);
        final fileSize = await fileObj.length();
        print(
          '📦 File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)',
        );

        // Проверяем размер файла в зависимости от модуля
        final maxSize = _getMaxSizeForModule(module);
        if (fileSize > maxSize) {
          print('❌ File too large: $fileSize > $maxSize');
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
        print('✅ MultipartFile created from path');
      } else {
        print('❌ No file data provided');
        print('   kIsWeb: $kIsWeb');
        print(
          '   fileBytes: ${fileBytes != null ? "${fileBytes.length} bytes" : "null"}',
        );
        print('   file: ${file ?? "null"}');
        throw Exception('Не указан файл для загрузки');
      }

      print('🚀 Sending multipart request...');
      final startTime = DateTime.now();

      // Отправляем запрос с таймаутом
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          print('❌ Upload timeout after 60 seconds');
          throw Exception(
            'Таймаут загрузки файла. Проверьте подключение к интернету.',
          );
        },
      );

      final duration = DateTime.now().difference(startTime);
      print('📥 Response received (${duration.inMilliseconds}ms)');
      print('📊 Status code: ${streamedResponse.statusCode}');
      print('📋 Response headers: ${streamedResponse.headers}');

      final responseBody = await streamedResponse.stream.bytesToString();
      print('📦 Response body length: ${responseBody.length} bytes');

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        print('✅ Upload successful');
        try {
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          final apiResponse = ApiResponse.fromJson(
            json,
            (data) =>
                StorageUploadResponse.fromJson(data as Map<String, dynamic>),
          );
          print('✅ File ID: ${apiResponse.data.fileId}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return apiResponse.data;
        } catch (e, stackTrace) {
          print('❌ Failed to parse response');
          print('   Error: $e');
          print('   Response body: $responseBody');
          print('   Stack trace: $stackTrace');
          rethrow;
        }
      } else if (streamedResponse.statusCode == 400) {
        print('❌ Bad request (400)');
        try {
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          final error = json['error'] as String? ?? 'Ошибка валидации файла';
          print('   Error message: $error');
          print('   Full response: $responseBody');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          throw Exception(error);
        } catch (e) {
          print('   Failed to parse error response: $e');
          print('   Raw response: $responseBody');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          throw Exception('Ошибка валидации файла');
        }
      } else if (streamedResponse.statusCode == 401) {
        print('❌ Unauthorized (401)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception('Не авторизован');
      } else {
        print('❌ Upload failed with status ${streamedResponse.statusCode}');
        try {
          final json = jsonDecode(responseBody) as Map<String, dynamic>;
          final error =
              json['error'] as String? ??
              json['message'] as String? ??
              'Ошибка при загрузке файла';
          print('   Error message: $error');
          print('   Full response: $responseBody');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          throw Exception(error);
        } catch (e) {
          print('   Failed to parse error response: $e');
          print('   Raw response: $responseBody');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          throw Exception(
            'Ошибка при загрузке файла (${streamedResponse.statusCode})',
          );
        }
      }
    } catch (e, stackTrace) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ FILE UPLOAD ERROR');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('💥 Error type: ${e.runtimeType}');
      print('💥 Error message: $e');
      print('📚 Stack trace:');
      print('$stackTrace');

      // Обработка специфичных ошибок для веба
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cors') ||
          errorString.contains('network') ||
          errorString.contains('failed to fetch') ||
          errorString.contains('networkerror')) {
        print('🌐 Detected network/CORS error');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(
          'Ошибка сети. Проверьте подключение к интернету и настройки CORS на сервере.',
        );
      } else if (errorString.contains('timeout')) {
        print('⏱️ Detected timeout error');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(
          'Таймаут загрузки файла. Файл слишком большой или медленное соединение.',
        );
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

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
