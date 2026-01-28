import '../models/model.dart';

/// Модель ответа при получении URL файла
class StorageUrlResponse extends Model {
  final String url;
  final DateTime expiresAt;

  const StorageUrlResponse({
    required this.url,
    required this.expiresAt,
  });

  factory StorageUrlResponse.fromJson(Map<String, dynamic> json) {
    return StorageUrlResponse(
      url: json['url'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
