import '../datasources/datasource.dart';
import '../models/invite_model.dart';

/// Удаленный источник данных для приглашений (API)
abstract class InviteRemoteDataSource extends DataSource {
  /// Создать новое приглашение (новый формат: возвращает список инвайтов)
  Future<InvitesListModel> createInvite({
    String? inviteType,
    int? maxUses,
    DateTime? expiresAt,
  });

  /// Получить текущие инвайты (новый формат: возвращает список инвайтов)
  /// Возвращает null, если инвайтов нет (404)
  Future<InvitesListModel?> getCurrentInvites();
}

