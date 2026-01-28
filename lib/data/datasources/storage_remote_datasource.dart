import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../datasources/datasource.dart';
import '../models/storage_upload_response.dart';

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
}
