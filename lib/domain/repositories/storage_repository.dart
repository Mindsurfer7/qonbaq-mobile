import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import 'repository.dart';
import '../../data/models/storage_upload_response.dart';
import '../../data/models/storage_url_response.dart';

/// Интерфейс репозитория для работы с storage
/// Реализация находится в data слое
abstract class StorageRepository extends Repository {
  /// Загрузить файл в storage
  /// 
  /// [file] - путь к файлу (для мобильных платформ)
  /// [fileBytes] - байты файла (для веб)
  /// [fileName] - имя файла
  /// [module] - модуль: 'attachments', 'assets', или 'receipts'
  Future<Either<Failure, StorageUploadResponse>> uploadFile({
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
  Future<Either<Failure, StorageUrlResponse>> getFileUrl({
    required String fileId,
    required String module,
    int expiresIn = 3600,
    String? extension,
  });

  /// Получить временную ссылку на файл по key
  /// 
  /// [key] - ключ файла в storage (bucket path)
  /// [bucket] - название bucket: 'attachments', 'assets', или 'receipts'
  /// [expiresIn] - время жизни ссылки в секундах (по умолчанию 3600)
  Future<Either<Failure, StorageUrlResponse>> getFileUrlByKey({
    required String key,
    required String bucket,
    int expiresIn = 3600,
  });
}
