import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/pending_confirmation.dart';
import '../../domain/usecases/get_pending_confirmations.dart';
import '../../domain/usecases/confirm_approval.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием pending confirmations и awaiting payment details
/// Автономно работает в фоне, делая запросы каждые 2 минуты
class PendingConfirmationsProvider with ChangeNotifier {
  final GetPendingConfirmations getPendingConfirmations;
  final ConfirmApproval confirmApproval;
  final GetNotifications getNotifications;

  PendingConfirmationsProvider({
    required this.getPendingConfirmations,
    required this.confirmApproval,
    required this.getNotifications,
  });

  List<PendingConfirmation> _pendingConfirmations = [];
  List<String> _awaitingPaymentDetailsIds = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  String? _currentBusinessId;
  
  // Хранилище данных формы платежных реквизитов по approvalId
  final Map<String, Map<String, dynamic>> _paymentDetailsFormData = {};

  /// Список pending confirmations
  List<PendingConfirmation> get pendingConfirmations => _pendingConfirmations;

  /// Список ID согласований, требующих заполнения payment details
  List<String> get awaitingPaymentDetailsIds => _awaitingPaymentDetailsIds;

  /// Количество pending confirmations
  int get pendingConfirmationsCount => _pendingConfirmations.length;

  /// Количество awaiting payment details
  int get awaitingPaymentDetailsCount => _awaitingPaymentDetailsIds.length;

  /// Общее количество оповещений (для навигационного бара)
  int get totalCount =>
      _pendingConfirmations.length + _awaitingPaymentDetailsIds.length;

  /// Количество pending confirmations (для обратной совместимости)
  @Deprecated('Используйте pendingConfirmationsCount')
  int get count => _pendingConfirmations.length;

  /// Есть ли pending confirmations или awaiting payment details
  bool get hasPending =>
      _pendingConfirmations.isNotEmpty || _awaitingPaymentDetailsIds.isNotEmpty;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список pending confirmations
  Future<void> loadPendingConfirmations({String? businessId}) async {
    debugPrint(
      '🔄 PendingConfirmationsProvider: Загрузка pending confirmations для businessId: $businessId',
    );
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getPendingConfirmations.call(
      GetPendingConfirmationsParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        final errorMessage = _getErrorMessage(failure);
        final hasErrorChanged = _error != errorMessage;
        final wasLoading = _isLoading;
        _error = errorMessage;
        _isLoading = false;
        // Уведомляем если:
        // 1. Ошибка изменилась
        // 2. Или изменился статус загрузки (была загрузка, стала нет)
        if (hasErrorChanged || wasLoading) {
          notifyListeners();
        }
      },
      (confirmations) {
        // Проверяем, изменились ли данные
        final oldCount = _pendingConfirmations.length;
        final newCount = confirmations.length;
        final hasDataChanged =
            oldCount != newCount ||
            !_areConfirmationsEqual(_pendingConfirmations, confirmations);

        _pendingConfirmations = confirmations;
        final wasLoading = _isLoading;
        _isLoading = false;
        _error = null;

        // Уведомляем если:
        // 1. Данные изменились
        // 2. Или изменился статус загрузки (была загрузка, стала нет)
        if (hasDataChanged || wasLoading) {
          if (hasDataChanged) {
            debugPrint(
              '✅ PendingConfirmationsProvider: Загружено ${confirmations.length} pending confirmations',
            );
          } else {
            debugPrint(
              '✅ PendingConfirmationsProvider: Данные не изменились (${confirmations.length} pending confirmations)',
            );
          }
          notifyListeners();
        }
      },
    );
  }

  /// Проверяет, равны ли два списка подтверждений
  bool _areConfirmationsEqual(
    List<PendingConfirmation> list1,
    List<PendingConfirmation> list2,
  ) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].approval.id != list2[i].approval.id) return false;
    }
    return true;
  }

  /// Загрузить список awaiting payment details
  Future<void> loadAwaitingPaymentDetails({String? businessId}) async {
    if (businessId == null) {
      final hadIds = _awaitingPaymentDetailsIds.isNotEmpty;
      _awaitingPaymentDetailsIds = [];
      // Уведомляем только если были ID
      if (hadIds) {
        notifyListeners();
      }
      return;
    }

    debugPrint(
      '🔄 PendingConfirmationsProvider: Загрузка awaiting payment details для businessId: $businessId',
    );

    final result = await getNotifications.call(
      GetNotificationsParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        // Игнорируем ошибки загрузки уведомлений, чтобы не блокировать основной список
        debugPrint(
          '⚠️ PendingConfirmationsProvider: Ошибка загрузки notifications: ${_getErrorMessage(failure)}',
        );
        final hadIds = _awaitingPaymentDetailsIds.isNotEmpty;
        _awaitingPaymentDetailsIds = [];
        // Уведомляем только если были ID
        if (hadIds) {
          notifyListeners();
        }
      },
      (notifications) {
        // Извлекаем ID согласований из awaitingPaymentDetails
        final awaitingPaymentDetails =
            notifications.accountant?.awaitingPaymentDetails ?? {};
        final newIds = awaitingPaymentDetails.keys.toList();

        // Проверяем, изменились ли данные
        final hasDataChanged =
            !_areStringListsEqual(_awaitingPaymentDetailsIds, newIds);

        _awaitingPaymentDetailsIds = newIds;

        // Уведомляем только если данные изменились
        if (hasDataChanged) {
          debugPrint(
            '✅ PendingConfirmationsProvider: Загружено ${_awaitingPaymentDetailsIds.length} awaiting payment details',
          );
          notifyListeners();
        } else {
          debugPrint(
            '✅ PendingConfirmationsProvider: Данные не изменились (${_awaitingPaymentDetailsIds.length} awaiting payment details)',
          );
        }
      },
    );
  }

  /// Проверяет, равны ли два списка строк
  bool _areStringListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    final set1 = list1.toSet();
    final set2 = list2.toSet();
    return set1.length == set2.length && set1.containsAll(set2);
  }

  /// Загрузить все оповещения (pending confirmations и awaiting payment details)
  Future<void> loadAll({String? businessId}) async {
    await Future.wait([
      loadPendingConfirmations(businessId: businessId),
      loadAwaitingPaymentDetails(businessId: businessId),
    ]);
  }

  /// Подтвердить согласование
  Future<bool> confirmApprovalAction({
    required String approvalId,
    required bool isConfirmed,
    double? amount,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await confirmApproval.call(
      ConfirmApprovalParams(
        approvalId: approvalId,
        isConfirmed: isConfirmed,
        amount: amount,
        comment: comment,
      ),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        // Если ошибка указывает, что подтверждение выполнено успешно
        // (например, если getApprovalById упал после успешного подтверждения),
        // считаем это успехом
        final errorMessage = _getErrorMessage(failure);
        if (errorMessage.contains('Подтверждение выполнено успешно')) {
          // Удаляем подтвержденное согласование из списка
          _pendingConfirmations.removeWhere(
            (pc) => pc.approval.id == approvalId,
          );
          _error = null;
          notifyListeners();
          return true;
        }

        _error = errorMessage;
        notifyListeners();
        return false;
      },
      (updatedApproval) {
        // Удаляем подтвержденное согласование из списка
        _pendingConfirmations.removeWhere((pc) => pc.approval.id == approvalId);
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить awaiting payment details после заполнения
  void removeAwaitingPaymentDetails(String approvalId) {
    _awaitingPaymentDetailsIds.remove(approvalId);
    // Очищаем сохраненные данные формы после успешного заполнения
    _paymentDetailsFormData.remove(approvalId);
    notifyListeners();
  }

  /// Сохранить данные формы платежных реквизитов
  void savePaymentDetailsFormData(String approvalId, Map<String, dynamic> formData) {
    _paymentDetailsFormData[approvalId] = Map<String, dynamic>.from(formData);
    // Не вызываем notifyListeners, так как это не влияет на UI напрямую
  }

  /// Получить сохраненные данные формы платежных реквизитов
  Map<String, dynamic>? getPaymentDetailsFormData(String approvalId) {
    final data = _paymentDetailsFormData[approvalId];
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Очистить сохраненные данные формы платежных реквизитов
  void clearPaymentDetailsFormData(String approvalId) {
    _paymentDetailsFormData.remove(approvalId);
  }

  /// Запустить периодические запросы (каждые 2 минуты)
  void startPolling({String? businessId}) {
    // Проверяем, был ли уже запущен polling с тем же businessId
    final wasRunning = _pollingTimer != null;
    final businessIdChanged = _currentBusinessId != businessId;

    // Останавливаем предыдущий таймер, если есть
    stopPolling();

    // Обновляем businessId ПЕРЕД запуском таймера
    _currentBusinessId = businessId;
    debugPrint(
      '🚀 PendingConfirmationsProvider: Запуск polling для businessId: $_currentBusinessId',
    );

    // Загружаем сразу все оповещения только если:
    // 1. Polling еще не был запущен (первый запуск)
    // 2. Или изменился businessId
    if (!wasRunning || businessIdChanged) {
      loadAll(businessId: businessId);
    }

    // Запускаем периодические запросы каждые 2 минуты
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      // Используем актуальное значение _currentBusinessId
      loadAll(businessId: _currentBusinessId);
    });
  }

  /// Остановить периодические запросы
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Обновить businessId и перезапустить polling
  void updateBusinessId(String? businessId) {
    if (_currentBusinessId != businessId) {
      debugPrint(
        '🔄 PendingConfirmationsProvider: Обновляем businessId с $_currentBusinessId на $businessId',
      );
      startPolling(businessId: businessId);
    }
  }

  /// Очистить все данные и остановить polling
  void clear() {
    debugPrint('🧹 PendingConfirmationsProvider: Очистка данных');
    stopPolling();
    _pendingConfirmations = [];
    _awaitingPaymentDetailsIds = [];
    _currentBusinessId = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
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
