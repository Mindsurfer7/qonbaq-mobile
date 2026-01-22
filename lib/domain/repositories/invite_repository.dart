import 'package:dartz/dartz.dart';
import '../entities/invite.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с приглашениями
/// Реализация находится в data слое
abstract class InviteRepository extends Repository {
  /// Создать новое приглашение (новый формат: возвращает список инвайтов)
  Future<Either<Failure, InvitesList>> createInvite({
    String? inviteType,
    int? maxUses,
    DateTime? expiresAt,
  });

  /// Получить текущие инвайты (новый формат: возвращает список инвайтов)
  /// Возвращает null в Right, если инвайтов нет (404)
  Future<Either<Failure, InvitesList?>> getCurrentInvites();
}

