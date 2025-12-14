import 'package:dartz/dartz.dart';
import '../../domain/entities/invite.dart';
import '../../domain/repositories/invite_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/invite_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория приглашений
/// Использует Remote DataSource
class InviteRepositoryImpl extends RepositoryImpl implements InviteRepository {
  final InviteRemoteDataSource remoteDataSource;

  InviteRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, CreateInviteResult>> createInvite({
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final result = await remoteDataSource.createInvite(
        maxUses: maxUses,
        expiresAt: expiresAt,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании приглашения: $e'));
    }
  }

  @override
  Future<Either<Failure, CreateInviteResult?>> getCurrentInvite() async {
    try {
      final result = await remoteDataSource.getCurrentInvite();
      return Right(result?.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении текущего приглашения: $e'));
    }
  }
}

