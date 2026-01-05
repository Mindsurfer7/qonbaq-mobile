import 'package:dartz/dartz.dart';
import '../entities/inbox_item.dart';
import '../../core/error/failures.dart';
import '../repositories/repository.dart';

/// Интерфейс репозитория для работы с Inbox Items
/// Реализация находится в data слое
abstract class InboxRepository extends Repository {
  /// Создать Inbox Item
  Future<Either<Failure, InboxItem>> createInboxItem(InboxItem inboxItem);

  /// Создать Inbox Item через голосовое сообщение
  /// 
  /// [audioFile] - путь к аудиофайлу (для не-веб платформ)
  /// [audioBytes] - байты аудиофайла (для веб-платформы)
  /// [filename] - имя файла
  /// [businessId] - ID бизнеса
  /// 
  /// Возвращает созданный Inbox Item
  Future<Either<Failure, InboxItem>> createInboxItemFromVoice({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String businessId,
  });

  /// Получить Inbox Item по ID
  Future<Either<Failure, InboxItem>> getInboxItemById(String id);

  /// Получить список Inbox Items
  Future<Either<Failure, List<InboxItem>>> getInboxItems({
    String? businessId,
    bool? isArchived,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  });

  /// Обновить Inbox Item
  Future<Either<Failure, InboxItem>> updateInboxItem(
    String id,
    InboxItem inboxItem,
  );

  /// Удалить Inbox Item
  Future<Either<Failure, void>> deleteInboxItem(String id);
}

