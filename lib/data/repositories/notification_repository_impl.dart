import 'package:dartz/dartz.dart';
import '../../domain/entities/user_actions_needed.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../core/error/failures.dart';
import '../datasources/notification_remote_datasource.dart';
import '../repositories/repository_impl.dart';

/// Реализация репозитория уведомлений
class NotificationRepositoryImpl extends RepositoryImpl
    implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, UserActionsNeeded>> getNotifications({
    required String businessId,
  }) async {
    try {
      final result = await remoteDataSource.getNotifications(
        businessId: businessId,
      );
      return Right(result.data.toEntity());
    } catch (e) {
      return Left(ServerFailure('Ошибка при получении уведомлений: $e'));
    }
  }
}
