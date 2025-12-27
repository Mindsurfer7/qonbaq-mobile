/// Модель ошибки валидации для конкретного поля
class ValidationError {
  final String field;
  final String message;
  final String code;

  ValidationError({
    required this.field,
    required this.message,
    required this.code,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] as String,
      message: json['message'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'message': message,
      'code': code,
    };
  }
}

/// Модель ответа с ошибками валидации от сервера
class ValidationErrorResponse {
  final String error;
  final String? message;
  final List<ValidationError> details;

  ValidationErrorResponse({
    required this.error,
    this.message,
    required this.details,
  });

  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    final detailsList = json['details'] as List<dynamic>? ?? [];
    return ValidationErrorResponse(
      error: json['error'] as String? ?? 'Ошибка валидации',
      message: json['message'] as String?,
      details: detailsList
          .map((item) => ValidationError.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}






