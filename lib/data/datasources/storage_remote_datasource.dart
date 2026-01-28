import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../datasources/datasource.dart';
import '../models/storage_upload_response.dart';
import '../models/storage_url_response.dart';

/// Удаленный источник данных для работы с storage (S3)
abstract class StorageRemoteDataSource extends DataSource {
  /// Загрузить файл в storage
  /// 
  /// [file] - путь к файлу (для мобильных платформ)
  /// [fileBytes] - байты файла (для веб)
  /// [fileName] - имя файла
  /// [module] - модуль: 'attachments', 'assets', или 'receipts'
  Future<StorageUploadResponse> uploadFile({
    String? file,
    List<int>? fileBytes,
    required String fileName,
    required String module,
  });

  /// Получить временную ссылку на файл по fileId
  /// 
  /// [fileId] - ID файла
  /// [module] - модуль: 'attachments', 'assets', или 'receipts'
  /// [expiresIn] - время жизни ссылки в секундах (по умолчанию 3600)
  /// [extension] - расширение файла (опционально)
  Future<StorageUrlResponse> getFileUrl({
    required String fileId,
    required String module,
    int expiresIn = 3600,
    String? extension,
  });
}
