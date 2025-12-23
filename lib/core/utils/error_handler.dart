import 'dart:convert';

/// Утилита для обработки ошибок HTTP ответов
class ErrorHandler {
  /// Получить понятное сообщение об ошибке из HTTP ответа
  /// 
  /// Парсит сообщение из поля `error` в body ответа.
  /// Если поле отсутствует, возвращает дефолтное сообщение.
  static String getErrorMessage(int statusCode, String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>?;
      
      // Приоритетно используем message, так как оно более информативное
      if (json != null && json.containsKey('message')) {
        final message = json['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      
      // Если message нет, используем error
      if (json != null && json.containsKey('error')) {
        final error = json['error'];
        if (error is String && error.isNotEmpty) {
          return error;
        }
      }
    } catch (e) {
      // Если не удалось распарсить JSON, игнорируем
    }
    
    // Дефолтные сообщения для разных статус-кодов
    switch (statusCode) {
      case 400:
        return 'Некорректный запрос';
      case 401:
        return 'Не авторизован';
      case 403:
        return 'Доступ запрещен';
      case 404:
        return 'Ресурс не найден';
      case 500:
        return 'Ошибка сервера';
      default:
        return 'Произошла ошибка при выполнении запроса';
    }
  }
}

