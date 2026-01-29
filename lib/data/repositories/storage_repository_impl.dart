import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/storage_remote_datasource.dart';
import '../models/storage_upload_response.dart';
import '../models/storage_url_response.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория для работы с storage
class StorageRepositoryImpl extends RepositoryImpl implements StorageRepository {
  final StorageRemoteDataSource remoteDataSource;

  StorageRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, StorageUploadResponse>> uploadFile({
    String? file,
    List<int>? fileBytes,
    required String fileName,
    required String module,
  }) async {
    try {
      final result = await remoteDataSource.uploadFile(
        file: file,
        fileBytes: fileBytes,
        fileName: fileName,
        module: module,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Ошибка при загрузке файла: $e'));
    }
  }

  @override
  Future<Either<Failure, StorageUrlResponse>> getFileUrl({
    required String fileId,
    required String module,
    int expiresIn = 3600,
    String? extension,
  }) async {
    try {
      final result = await remoteDataSource.getFileUrl(
        fileId: fileId,
        module: module,
        expiresIn: expiresIn,
        extension: extension,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении URL файла: $e'));
    }
  }

  @override
  Future<Either<Failure, StorageUrlResponse>> getFileUrlByKey({
    required String key,
    required String bucket,
    int expiresIn = 3600,
  }) async {
    try {
      final result = await remoteDataSource.getFileUrlByKey(
        key: key,
        bucket: bucket,
        expiresIn: expiresIn,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении URL файла: $e'));
    }
  }
}
