import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../domain/repositories/storage_repository.dart';
import '../datasources/storage_remote_datasource.dart';
import '../models/storage_upload_response.dart';
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
}
