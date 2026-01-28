import '../models/model.dart';

/// Модель ответа при загрузке файла в storage
class StorageUploadResponse extends Model {
  final String fileId;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String bucket;
  final String key;

  const StorageUploadResponse({
    required this.fileId,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.bucket,
    required this.key,
  });

  factory StorageUploadResponse.fromJson(Map<String, dynamic> json) {
    return StorageUploadResponse(
      fileId: json['fileId'] as String,
      fileName: json['fileName'] as String,
      fileSize: json['fileSize'] as int,
      mimeType: json['mimeType'] as String,
      bucket: json['bucket'] as String,
      key: json['key'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'bucket': bucket,
      'key': key,
    };
  }
}
