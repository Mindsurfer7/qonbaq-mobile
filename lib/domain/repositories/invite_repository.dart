import 'package:dartz/dartz.dart';
import '../entities/invite.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с приглашениями
/// Реализация находится в data слое
abstract class InviteRepository extends Repository {
  /// Создать новое приглашение
  Future<Either<Failure, CreateInviteResult>> createInvite({
    int? maxUses,
    DateTime? expiresAt,
  });

  /// Получить текущий активный инвайт
  /// Возвращает null в Right, если активного инвайта нет (404)
  Future<Either<Failure, CreateInviteResult?>> getCurrentInvite();
}

