import '../../domain/entities/inbox_item.dart';
import '../datasources/datasource.dart';
import '../models/inbox_item_model.dart';

/// Удаленный источник данных для Inbox Items (API)
abstract class InboxRemoteDataSource extends DataSource {
  /// Создать Inbox Item
  Future<InboxItemModel> createInboxItem(InboxItemModel inboxItem);

  /// Создать Inbox Item через голосовое сообщение
  /// 
  /// [audioFile] - путь к аудиофайлу (для не-веб платформ)
  /// [audioBytes] - байты аудиофайла (для веб-платформы)
  /// [filename] - имя файла
  /// [businessId] - ID бизнеса
  /// 
  /// Возвращает созданный Inbox Item
  Future<InboxItemModel> createInboxItemFromVoice({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String businessId,
  });

  /// Получить Inbox Item по ID
  Future<InboxItemModel> getInboxItemById(String id);

  /// Получить список Inbox Items
  Future<List<InboxItemModel>> getInboxItems({
    String? businessId,
    bool? isArchived,
    InboxItemCategory? category,
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

