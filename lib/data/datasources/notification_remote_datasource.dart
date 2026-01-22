import '../datasources/datasource.dart';
import '../models/api_response.dart';
import '../../domain/entities/user_actions_needed.dart';
import '../models/user_actions_needed_model.dart';

/// Удаленный источник данных для уведомлений (API)
abstract class NotificationRemoteDataSource extends DataSource {
  /// Получить действия, требуемые от пользователя
  Future<ApiResponse<UserActionsNeededModel>> getNotifications({
    required String businessId,
  });
}
