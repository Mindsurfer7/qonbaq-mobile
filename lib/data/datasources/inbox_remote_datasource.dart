import '../datasources/datasource.dart';
import '../models/inbox_item_model.dart';

/// Удаленный источник данных для Inbox Items (API)
abstract class InboxRemoteDataSource extends DataSource {
  /// Создать Inbox Item
  Future<InboxItemModel> createInboxItem(InboxItemModel inboxItem);

  /// Получить Inbox Item по ID
  Future<InboxItemModel> getInboxItemById(String id);

  /// Получить список Inbox Items
  Future<List<InboxItemModel>> getInboxItems({
    String? businessId,
    bool? isArchived,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  });

  /// Обновить Inbox Item
  Future<InboxItemModel> updateInboxItem(String id, InboxItemModel inboxItem);

  /// Удалить Inbox Item
  Future<void> deleteInboxItem(String id);
}

