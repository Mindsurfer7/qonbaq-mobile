import '../datasources/datasource.dart';
import '../models/invite_model.dart';

/// Удаленный источник данных для приглашений (API)
abstract class InviteRemoteDataSource extends DataSource {
  /// Создать новое приглашение
  Future<CreateInviteResultModel> createInvite({
    int? maxUses,
    DateTime? expiresAt,
  });

  /// Получить текущий активный инвайт
  /// Возвращает null, если активного инвайта нет (404)
  Future<CreateInviteResultModel?> getCurrentInvite();
}

