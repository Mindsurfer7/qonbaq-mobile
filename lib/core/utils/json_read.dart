/// Утилиты для безопасного чтения JSON.
///
/// Цель: не падать на `null as String` / `DateTime.parse(null)`,
/// а также давать понятные ошибки формата данных (FormatException).
library;

extension JsonRead on Map<String, dynamic> {
  String? readString(String key) => this[key] as String?;

  String readRequiredString(String key) {
    final v = this[key];
    if (v is String && v.isNotEmpty) return v;
    throw FormatException('Ожидался непустой String в поле "$key", получено: $v (${v.runtimeType})');
  }

  DateTime? readDateTimeNullable(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  DateTime readDateTimeOrEpoch(String key) {
    return readDateTimeNullable(key) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Map<String, dynamic>? readMap(String key) {
    final v = this[key];
    if (v is Map<String, dynamic>) return v;
    return null;
  }

  List<dynamic>? readList(String key) {
    final v = this[key];
    if (v is List) return v;
    return null;
  }
}


