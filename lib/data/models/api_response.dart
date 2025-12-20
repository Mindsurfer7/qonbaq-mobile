/// Стандартный формат ответа API
/// 
/// Все успешные ответы API теперь используют обертку `data`.
/// Для списков также может быть поле `meta` с информацией о пагинации.
class ApiResponse<T> {
  final T data;
  final ApiMeta? meta;

  ApiResponse({
    required this.data,
    this.meta,
  });

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

    // Парсим data используя переданную функцию
    final parsedData = fromJsonT(dataJson);

    // Парсим meta, если есть
    ApiMeta? parsedMeta;
    if (json['meta'] != null) {
      parsedMeta = ApiMeta.fromJson(json['meta'] as Map<String, dynamic>);
    }

    return ApiResponse<T>(
      data: parsedData,
      meta: parsedMeta,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      if (meta != null) 'meta': meta!.toJson(),
    };
  }
}

/// Метаданные для пагинации и статистики
class ApiMeta {
  final int? total;
  final int? page;
  final int? limit;
  final int? totalPages;
  final int? count;

  ApiMeta({
    this.total,
    this.page,
    this.limit,
    this.totalPages,
    this.count,
  });

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      total: json['total'] as int?,
      page: json['page'] as int?,
      limit: json['limit'] as int?,
      totalPages: json['totalPages'] as int?,
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (total != null) 'total': total,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (totalPages != null) 'totalPages': totalPages,
      if (count != null) 'count': count,
    };
  }
}

