import 'package:dartz/dartz.dart';
import '../../core/usecase/usecase.dart';
import '../../core/error/failures.dart';
import '../entities/user_actions_needed.dart';
import '../repositories/notification_repository.dart';

/// Параметры для получения уведомлений
class GetNotificationsParams {
  final String businessId;

  GetNotificationsParams({required this.businessId});
}

/// Use case для получения уведомлений
class GetNotifications implements UseCase<UserActionsNeeded, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  @override
  Future<Either<Failure, UserActionsNeeded>> call(
    GetNotificationsParams params,
  ) async {
    return await repository.getNotifications(businessId: params.businessId);
  }
}
