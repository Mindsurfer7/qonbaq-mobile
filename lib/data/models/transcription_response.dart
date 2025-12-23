/// Модель ответа транскрипции аудио
class TranscriptionResponse {
  final String text;
  final TranscriptionMetadata? metadata;

  TranscriptionResponse({
    required this.text,
    this.metadata,
  });

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(
      text: json['text'] ?? '',
      metadata: json['metadata'] != null
          ? TranscriptionMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      if (metadata != null) 'metadata': metadata!.toJson(),
    };
  }

  @override
  String toString() {
    return 'TranscriptionResponse(text: $text)';
  }
}

/// Метаданные транскрипции
class TranscriptionMetadata {
  final String? language;
  final double? duration;

  TranscriptionMetadata({
    this.language,
    this.duration,
  });

  factory TranscriptionMetadata.fromJson(Map<String, dynamic> json) {
    return TranscriptionMetadata(
      language: json['language'] as String?,
      duration: json['duration'] != null ? (json['duration'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (language != null) 'language': language,
      if (duration != null) 'duration': duration,
    };
  }
}

