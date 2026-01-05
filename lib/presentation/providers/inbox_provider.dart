import 'package:flutter/foundation.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/usecases/get_inbox_items.dart';
import '../../domain/usecases/create_inbox_item.dart';
import '../../domain/usecases/create_inbox_item_from_voice.dart';
import '../../domain/usecases/update_inbox_item.dart';
import '../../domain/usecases/delete_inbox_item.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием Inbox Items
class InboxProvider with ChangeNotifier {
  final GetInboxItems getInboxItems;
  final CreateInboxItem createInboxItem;
  final CreateInboxItemFromVoice createInboxItemFromVoice;
  final UpdateInboxItem updateInboxItem;
  final DeleteInboxItem deleteInboxItem;

  InboxProvider({
    required this.getInboxItems,
    required this.createInboxItem,
    required this.createInboxItemFromVoice,
    required this.updateInboxItem,
    required this.deleteInboxItem,
  });

  List<InboxItem>? _items;
  bool _isLoading = false;
  String? _error;

  /// Список Inbox Items
  List<InboxItem>? get items => _items;

  /// Активные Inbox Items (не заархивированные)
  List<InboxItem> get activeItems =>
      _items?.where((item) => !item.isArchived).toList() ?? [];

  /// Заархивированные Inbox Items
  List<InboxItem> get archivedItems =>
      _items?.where((item) => item.isArchived).toList() ?? [];

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список Inbox Items
  Future<void> loadInboxItems({
    String? businessId,
    bool? isArchived,
    InboxItemCategory? category,
    int? page,
    int? limit,
    String? sortBy,
    String? sortOrder,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getInboxItems.call(
      GetInboxItemsParams(
        businessId: businessId,
        isArchived: isArchived,
        category: category,
        page: page,
        limit: limit,
        sortBy: sortBy,
        sortOrder: sortOrder,
      ),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (items) {
        _items = items;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Создать Inbox Item
  Future<bool> createItem({
    required String businessId,
    String? title,
    String? description,
    InboxItemCategory? category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final inboxItem = InboxItem(
      id: '', // Будет присвоен на сервере
      userId: '', // Будет присвоен на сервере
      businessId: businessId,
      title: title,
      description: description,
      isArchived: false,
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await createInboxItem.call(
      CreateInboxItemParams(inboxItem: inboxItem),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (createdItem) {
        // Добавляем новый item в список
        _items ??= [];
        _items!.insert(0, createdItem);
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Создать Inbox Item через голосовое сообщение
  Future<bool> createItemFromVoice({
    String? audioFile,
    List<int>? audioBytes,
    String filename = 'voice.m4a',
    required String businessId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createInboxItemFromVoice.call(
      CreateInboxItemFromVoiceParams(
        audioFile: audioFile,
        audioBytes: audioBytes,
        filename: filename,
        businessId: businessId,
      ),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (createdItem) {
        // Оптимистично добавляем новый item в список
        _items ??= [];
        _items!.insert(0, createdItem);
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить Inbox Item
  Future<bool> updateItem({
    required String id,
    String? title,
    String? description,
    bool? isArchived,
    InboxItemCategory? category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Находим существующий item
    final existingItem = _items?.firstWhere(
      (item) => item.id == id,
      orElse: () => throw Exception('Item не найден'),
    );

    if (existingItem == null) {
      _isLoading = false;
      _error = 'Item не найден';
      notifyListeners();
      return false;
    }

    // Используем переданные значения или существующие
    final updatedItem = InboxItem(
      id: existingItem.id,
      userId: existingItem.userId,
      businessId: existingItem.businessId,
      title: title ?? existingItem.title,
      description: description ?? existingItem.description,
      isArchived: isArchived ?? existingItem.isArchived,
      // Если category передан, используем его, иначе оставляем существующий
      category: category ?? existingItem.category,
      createdAt: existingItem.createdAt,
      updatedAt: DateTime.now(),
      user: existingItem.user,
      business: existingItem.business,
    );

    final result = await updateInboxItem.call(
      UpdateInboxItemParams(id: id, inboxItem: updatedItem),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (updated) {
        // Обновляем item в списке
        final index = _items!.indexWhere((item) => item.id == id);
        if (index != -1) {
          _items![index] = updated;
        }
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Удалить Inbox Item
  Future<bool> deleteItem(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await deleteInboxItem.call(DeleteInboxItemParams(id: id));

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (_) {
        // Удаляем item из списка
        _items?.removeWhere((item) => item.id == id);
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is ValidationFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
