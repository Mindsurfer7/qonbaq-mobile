import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../data/models/storage_url_response.dart';
import '../repositories/storage_repository.dart';

/// Параметры для получения URL файла
class GetFileUrlParams {
  final String fileId;
  final String module;
  final int expiresIn;
  final String? extension;

  GetFileUrlParams({
    required this.fileId,
    required this.module,
    this.expiresIn = 3600,
    this.extension,
  });
}

/// Use Case для получения временной ссылки на файл
class GetFileUrl implements UseCase<StorageUrlResponse, GetFileUrlParams> {
  final StorageRepository repository;

  GetFileUrl(this.repository);

  @override
  Future<Either<Failure, StorageUrlResponse>> call(GetFileUrlParams params) async {
    return await repository.getFileUrl(
      fileId: params.fileId,
      module: params.module,
      expiresIn: params.expiresIn,
      extension: params.extension,
    );
  }
}
