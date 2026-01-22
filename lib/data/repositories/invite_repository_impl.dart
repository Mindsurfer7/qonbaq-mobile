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
  Future<Either<Failure, InvitesList>> createInvite({
    String? inviteType,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final result = await remoteDataSource.createInvite(
        inviteType: inviteType,
        maxUses: maxUses,
        expiresAt: expiresAt,
      );
      return Right(result.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при создании приглашения: $e'));
    }
  }

  @override
  Future<Either<Failure, InvitesList?>> getCurrentInvites() async {
    try {
      final result = await remoteDataSource.getCurrentInvites();
      return Right(result?.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении текущих приглашений: $e'));
    }
  }
}

