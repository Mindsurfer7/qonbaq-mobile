/// Стандартный формат ответа API
///
/// Все успешные ответы API теперь используют обертку `data`.
/// Для списков также может быть поле `meta` с информацией о пагинации.
class ApiResponse<T> {
  final T data;
  final ApiMeta? meta;

  ApiResponse({required this.data, this.meta});

  /// Нормализует входные данные: Map → Map<String,dynamic>, List → List<dynamic>.
  /// Это позволяет избежать TypeError при кастах `as Map<String,dynamic>` на ответах 200/201.
  /// ВАЖНО: Делает ГЛУБОКУЮ нормализацию всех вложенных Map и List.
  static dynamic _normalizeData(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(
            e.key.toString(),
            _normalizeData(e.value), // Рекурсивно нормализуем значения
          ),
        ),
      );
    }
    if (value is List) {
      return value
          .map((e) => _normalizeData(e))
          .toList(); // Рекурсивно нормализуем элементы
    }
    return value;
  }

  /// Жёстко требует Map, иначе бросает FormatException с контекстом.
  static Map<String, dynamic> expectMap(dynamic value, {String? where}) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException(
      'Ожидался Map в ApiResponse.data${where != null ? ' ($where)' : ''}, '
      'получено ${value.runtimeType}: $value',
    );
  }

  /// Жёстко требует List, иначе бросает FormatException с контекстом.
  static List<dynamic> expectList(dynamic value, {String? where}) {
    if (value is List<dynamic>) return value;
    if (value is List) return List<dynamic>.from(value);
    throw FormatException(
      'Ожидался List в ApiResponse.data${where != null ? ' ($where)' : ''}, '
      'получено ${value.runtimeType}: $value',
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    // Извлекаем data
    final dataJson = json['data'];
    if (dataJson == null) {
      throw FormatException(
        'Ожидалось поле "data" в ответе API, получено: $json',
      );
    }

    // Нормализуем data (Map/List) и парсим с обработкой ошибок
    late final T parsedData;
    try {
      final normalized = _normalizeData(dataJson);
      parsedData = fromJsonT(normalized);
    } catch (e) {
      throw FormatException(
        'Не удалось распарсить ApiResponse.data: $e; data=$dataJson',
      );
    }

    // Парсим meta, если есть
    ApiMeta? parsedMeta;
    if (json['meta'] != null) {
      parsedMeta = ApiMeta.fromJson(json['meta'] as Map<String, dynamic>);
    }

    return ApiResponse<T>(data: parsedData, meta: parsedMeta);
  }

  Map<String, dynamic> toJson() {
    return {'data': data, if (meta != null) 'meta': meta!.toJson()};
  }
}

/// Метаданные для пагинации и статистики
class ApiMeta {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;
  final int? count;
  final List<MissingRole>? missingRoles;
  final int? totalMissing;
  final List<UnassignedRole>? unassignedRoles;
  final String? message;

  ApiMeta({
    this.total,
    this.page,
    this.limit,
    this.totalPages,
    this.count,
    this.missingRoles,
    this.totalMissing,
    this.unassignedRoles,
    this.message,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    List<MissingRole>? missingRoles;
    if (json['missingRoles'] != null) {
      final rolesList = json['missingRoles'] as List<dynamic>;
      missingRoles =
          rolesList
              .map((role) => MissingRole.fromJson(role as Map<String, dynamic>))
              .toList();
    }

    List<UnassignedRole>? unassignedRoles;
    if (json['unassignedRoles'] != null) {
      final rolesList = json['unassignedRoles'] as List<dynamic>;
      unassignedRoles =
          rolesList
              .map(
                (role) => UnassignedRole.fromJson(role as Map<String, dynamic>),
              )
              .toList();
    }

    return ApiMeta(
      total: json['total'] as int?,
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      totalPages: json['totalPages'] as int?,
      count: json['count'] as int?,
      missingRoles: missingRoles,
      totalMissing: json['totalMissing'] as int?,
      unassignedRoles: unassignedRoles,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (total != null) 'total': total,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (totalPages != null) 'totalPages': totalPages,
      if (count != null) 'count': count,
      if (missingRoles != null)
        'missingRoles': missingRoles!.map((r) => r.toJson()).toList(),
      if (totalMissing != null) 'totalMissing': totalMissing,
      if (unassignedRoles != null)
        'unassignedRoles': unassignedRoles!.map((r) => r.toJson()).toList(),
      if (message != null) 'message': message,
    };
  }
}

/// Модель неназначенной роли (для CEO)
class UnassignedRole {
  final String code;
  final String name;

  UnassignedRole({required this.code, required this.name});

  factory UnassignedRole.fromJson(Map<String, dynamic> json) {
    return UnassignedRole(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name};
  }
}

/// Модель отсутствующей роли
class MissingRole {
  final String roleCode;
  final String roleName;
  final List<AffectedTemplate> affectedTemplates;

  MissingRole({
    required this.roleCode,
    required this.roleName,
    required this.affectedTemplates,
  });

  factory MissingRole.fromJson(Map<String, dynamic> json) {
    final templatesList = json['affectedTemplates'] as List<dynamic>;
    final templates =
        templatesList
            .map(
              (template) =>
                  AffectedTemplate.fromJson(template as Map<String, dynamic>),
            )
            .toList();

    return MissingRole(
      roleCode: json['roleCode'] as String,
      roleName: json['roleName'] as String,
      affectedTemplates: templates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roleCode': roleCode,
      'roleName': roleName,
      'affectedTemplates': affectedTemplates.map((t) => t.toJson()).toList(),
    };
  }
}

/// Модель шаблона, затронутого отсутствующей ролью
class AffectedTemplate {
  final String id;
  final String name;
  final String code;

  AffectedTemplate({required this.id, required this.name, required this.code});

  factory AffectedTemplate.fromJson(Map<String, dynamic> json) {
    return AffectedTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'code': code};
  }
}
