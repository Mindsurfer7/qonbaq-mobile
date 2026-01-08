/// Утилиты для безопасного парсинга JSON.
///
/// Централизованный способ избежать `type 'Null' is not a subtype of Map/List`
/// при неправильной форме ответа или отсутствии поля.
class JsonUtils {
  /// Возвращает `Map<String, dynamic>` или пустую Map, если `value` не Map/null.
  static Map<String, dynamic> mapOrEmpty(
    dynamic value, {
    String? fieldName,
  }) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  /// Возвращает `List<dynamic>` или пустой список, если `value` не List/null.
  static List<dynamic> listOrEmpty(dynamic value, {String? fieldName}) {
    if (value is List<dynamic>) return value;
    if (value is List) return List<dynamic>.from(value);
    return <dynamic>[];
  }

  /// Безопасно приводит значение к типу T или возвращает null.
  static T? asOrNull<T>(dynamic value) => value is T ? value : null;
}
