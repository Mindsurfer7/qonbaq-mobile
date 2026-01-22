import 'package:dartz/dartz.dart';
import '../entities/user_actions_needed.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с уведомлениями
abstract class NotificationRepository extends Repository {
  /// Получить действия, требуемые от пользователя
  Future<Either<Failure, UserActionsNeeded>> getNotifications({
    required String businessId,
  });
}
