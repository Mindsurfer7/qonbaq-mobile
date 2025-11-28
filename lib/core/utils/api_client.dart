import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_interceptor.dart';
import 'token_storage.dart';

/// HTTP клиент для работы с API
class ApiClient {
  final String baseUrl;
  final http.Client client;
  final AuthInterceptor? authInterceptor;

  ApiClient({required this.baseUrl, http.Client? client, this.authInterceptor})
    : client = client ?? http.Client();

  /// Логирование HTTP запроса
  void _logRequest(
    String method,
    Uri url,
    Map<String, String>? headers, {
    Object? body,
  }) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🌐 HTTP REQUEST');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 Method: $method');
    print('🔗 URL: $url');
    if (headers != null && headers.isNotEmpty) {
      print('📋 Headers:');
      headers.forEach((key, value) {
        // Маскируем токен для безопасности
        if (key.toLowerCase() == 'authorization') {
          final masked =
              value.length > 20 ? '${value.substring(0, 20)}...' : '***';
          print('   $key: $masked');
        } else {
          print('   $key: $value');
        }
      });
    }
    if (body != null) {
      print('📦 Body:');
      if (body is String) {
        try {
          final json = jsonDecode(body);
          print('   ${const JsonEncoder.withIndent('   ').convert(json)}');
        } catch (e) {
          print('   $body');
        }
      } else {
        print('   ${const JsonEncoder.withIndent('   ').convert(body)}');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Логирование HTTP ответа
  void _logResponse(http.Response response, {bool isRetry = false}) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📥 HTTP RESPONSE ${isRetry ? "(RETRY)" : ""}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📊 Status Code: ${response.statusCode}');
    print('📋 Headers:');
    response.headers.forEach((key, value) {
      print('   $key: $value');
    });
    print('📦 Body:');
    try {
      final json = jsonDecode(response.body);
      print('   ${const JsonEncoder.withIndent('   ').convert(json)}');
    } catch (e) {
      print('   ${response.body}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Логирование ошибки
  void _logError(
    String method,
    Uri url,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ HTTP ERROR');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 Method: $method');
    print('🔗 URL: $url');
    print('💥 Error: $error');
    if (stackTrace != null) {
      print('📚 Stack Trace:');
      print('   $stackTrace');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// GET запрос
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('GET', url, headers);

    try {
      var response = await client.get(url, headers: headers);
      _logResponse(response);

      // Обрабатываем через интерсептор, если он есть
      if (authInterceptor != null && response.statusCode == 401) {
        final shouldRetry = await authInterceptor!.interceptResponse(response);
        if (shouldRetry) {
          // Обновляем заголовки с новым токеном
          final newHeaders = Map<String, String>.from(headers ?? {});
          final newToken = _getAccessToken();
          if (newToken != null) {
            newHeaders['Authorization'] = 'Bearer $newToken';
          }
          // Повторяем запрос
          print('🔄 Retrying GET request after token refresh...');
          response = await client.get(url, headers: newHeaders);
          _logResponse(response, isRetry: true);
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logError('GET', url, e, stackTrace);
      rethrow;
    }
  }

  /// POST запрос
  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {'Content-Type': 'application/json', ...?headers};
    final bodyString = body != null ? jsonEncode(body) : null;
    _logRequest('POST', url, defaultHeaders, body: body);

    try {
      var response = await client.post(
        url,
        headers: defaultHeaders,
        body: bodyString,
      );
      _logResponse(response);

      // Обрабатываем через интерсептор, если он есть
      if (authInterceptor != null && response.statusCode == 401) {
        final shouldRetry = await authInterceptor!.interceptResponse(response);
        if (shouldRetry) {
          // Обновляем заголовки с новым токеном
          final newHeaders = Map<String, String>.from(defaultHeaders);
          final newToken = await _getAccessToken();
          if (newToken != null) {
            newHeaders['Authorization'] = 'Bearer $newToken';
          }
          // Повторяем запрос
          print('🔄 Retrying POST request after token refresh...');
          response = await client.post(
            url,
            headers: newHeaders,
            body: bodyString,
          );
          _logResponse(response, isRetry: true);
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logError('POST', url, e, stackTrace);
      rethrow;
    }
  }

  /// PUT запрос
  Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {'Content-Type': 'application/json', ...?headers};
    final bodyString = body != null ? jsonEncode(body) : null;
    _logRequest('PUT', url, defaultHeaders, body: body);

    try {
      var response = await client.put(
        url,
        headers: defaultHeaders,
        body: bodyString,
      );
      _logResponse(response);

      // Обрабатываем через интерсептор, если он есть
      if (authInterceptor != null && response.statusCode == 401) {
        final shouldRetry = await authInterceptor!.interceptResponse(response);
        if (shouldRetry) {
          // Обновляем заголовки с новым токеном
          final newHeaders = Map<String, String>.from(defaultHeaders);
          final newToken = await _getAccessToken();
          if (newToken != null) {
            newHeaders['Authorization'] = 'Bearer $newToken';
          }
          // Повторяем запрос
          print('🔄 Retrying PUT request after token refresh...');
          response = await client.put(
            url,
            headers: newHeaders,
            body: bodyString,
          );
          _logResponse(response, isRetry: true);
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logError('PUT', url, e, stackTrace);
      rethrow;
    }
  }

  /// DELETE запрос
  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    _logRequest('DELETE', url, headers);

    try {
      var response = await client.delete(url, headers: headers);
      _logResponse(response);

      // Обрабатываем через интерсептор, если он есть
      if (authInterceptor != null && response.statusCode == 401) {
        final shouldRetry = await authInterceptor!.interceptResponse(response);
        if (shouldRetry) {
          // Обновляем заголовки с новым токеном
          final newHeaders = Map<String, String>.from(headers ?? {});
          final newToken = _getAccessToken();
          if (newToken != null) {
            newHeaders['Authorization'] = 'Bearer $newToken';
          }
          // Повторяем запрос
          print('🔄 Retrying DELETE request after token refresh...');
          response = await client.delete(url, headers: newHeaders);
          _logResponse(response, isRetry: true);
        }
      }

      return response;
    } catch (e, stackTrace) {
      _logError('DELETE', url, e, stackTrace);
      rethrow;
    }
  }

  /// Получить access токен из хранилища
  String? _getAccessToken() {
    return TokenStorage.instance.getAccessToken();
  }
}
