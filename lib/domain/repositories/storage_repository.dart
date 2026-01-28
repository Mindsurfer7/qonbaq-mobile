import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import 'repository.dart';
import '../../data/models/storage_upload_response.dart';

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
}
