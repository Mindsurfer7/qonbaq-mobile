import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';
import '../../data/models/storage_upload_response.dart';
import '../repositories/storage_repository.dart';

/// Параметры для загрузки файла
class UploadFileParams {
  final String? file;
  final List<int>? fileBytes;
  final String fileName;
  final String module;

  UploadFileParams({
    this.file,
    this.fileBytes,
    required this.fileName,
    required this.module,
  });
}

/// Use Case для загрузки файла в storage
class UploadFile implements UseCase<StorageUploadResponse, UploadFileParams> {
  final StorageRepository repository;

  UploadFile(this.repository);

  @override
  Future<Either<Failure, StorageUploadResponse>> call(UploadFileParams params) async {
    return await repository.uploadFile(
      file: params.file,
      fileBytes: params.fileBytes,
      fileName: params.fileName,
      module: params.module,
    );
  }
}
