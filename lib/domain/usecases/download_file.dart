import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../data/models/storage_url_response.dart';
import '../repositories/storage_repository.dart';

/// Параметры для скачивания файла
class DownloadFileParams {
  /// ID файла (если есть)
  final String? fileId;
  
  /// Ключ файла в storage (если есть)
  final String? key;
  
  /// Модуль/bucket: 'attachments', 'assets', или 'receipts'
  final String module;
  
  /// Расширение файла (опционально, используется только с fileId)
  final String? extension;
  
  /// Время жизни ссылки в секундах
  final int expiresIn;

  DownloadFileParams({
    this.fileId,
    this.key,
    required this.module,
    this.extension,
    this.expiresIn = 3600,
  }) : assert(
          fileId != null || key != null,
          'Необходимо указать либо fileId, либо key',
        );
}

/// Use Case для скачивания файла
/// 
/// Получает временную signed URL для скачивания файла.
/// Поддерживает два варианта:
/// 1. По fileId: GET /api/storage/:fileId/url?module=attachments&extension=pdf
/// 2. По key: GET /api/storage/url?bucket=attachments&key=<key>&expiresIn=3600
class DownloadFile implements UseCase<StorageUrlResponse, DownloadFileParams> {
  final StorageRepository repository;

  DownloadFile(this.repository);

  @override
  Future<Either<Failure, StorageUrlResponse>> call(
    DownloadFileParams params,
  ) async {
    // Если есть fileId, используем его
    if (params.fileId != null) {
      return await repository.getFileUrl(
        fileId: params.fileId!,
        module: params.module,
        expiresIn: params.expiresIn,
        extension: params.extension,
      );
    }
    
    // Иначе используем key
    return await repository.getFileUrlByKey(
      key: params.key!,
      bucket: params.module,
      expiresIn: params.expiresIn,
    );
  }
}
