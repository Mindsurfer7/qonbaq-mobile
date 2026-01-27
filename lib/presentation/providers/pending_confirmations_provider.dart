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

  /// Список pending confirmations
  List<PendingConfirmation> get pendingConfirmations => _pendingConfirmations;

  /// Список ID согласований, требующих заполнения payment details
  List<String> get awaitingPaymentDetailsIds => _awaitingPaymentDetailsIds;

  /// Количество pending confirmations
  int get pendingConfirmationsCount => _pendingConfirmations.length;

  /// Количество awaiting payment details
  int get awaitingPaymentDetailsCount => _awaitingPaymentDetailsIds.length;

  /// Общее количество оповещений (для навигационного бара)
  int get totalCount => _pendingConfirmations.length + _awaitingPaymentDetailsIds.length;

  /// Количество pending confirmations (для обратной совместимости)
  @Deprecated('Используйте pendingConfirmationsCount')
  int get count => _pendingConfirmations.length;

  /// Есть ли pending confirmations или awaiting payment details
  bool get hasPending => _pendingConfirmations.isNotEmpty || _awaitingPaymentDetailsIds.isNotEmpty;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список pending confirmations
  Future<void> loadPendingConfirmations({String? businessId}) async {
    debugPrint('🔄 PendingConfirmationsProvider: Загрузка pending confirmations для businessId: $businessId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getPendingConfirmations.call(
      GetPendingConfirmationsParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (confirmations) {
        _pendingConfirmations = confirmations;
        _isLoading = false;
        _error = null;
        debugPrint('✅ PendingConfirmationsProvider: Загружено ${confirmations.length} pending confirmations');
        notifyListeners();
      },
    );
  }

  /// Загрузить список awaiting payment details
  Future<void> loadAwaitingPaymentDetails({String? businessId}) async {
    if (businessId == null) {
      _awaitingPaymentDetailsIds = [];
      notifyListeners();
      return;
    }

    debugPrint('🔄 PendingConfirmationsProvider: Загрузка awaiting payment details для businessId: $businessId');
    
    final result = await getNotifications.call(
      GetNotificationsParams(businessId: businessId),
    );

    result.fold(
      (failure) {
        // Игнорируем ошибки загрузки уведомлений, чтобы не блокировать основной список
        debugPrint('⚠️ PendingConfirmationsProvider: Ошибка загрузки notifications: ${_getErrorMessage(failure)}');
        _awaitingPaymentDetailsIds = [];
        notifyListeners();
      },
      (notifications) {
        // Извлекаем ID согласований из awaitingPaymentDetails
        final awaitingPaymentDetails =
            notifications.accountant?.awaitingPaymentDetails ?? {};
        _awaitingPaymentDetailsIds = awaitingPaymentDetails.keys.toList();
        debugPrint('✅ PendingConfirmationsProvider: Загружено ${_awaitingPaymentDetailsIds.length} awaiting payment details');
        notifyListeners();
      },
    );
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
        _pendingConfirmations.removeWhere(
          (pc) => pc.approval.id == approvalId,
        );
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Обновить awaiting payment details после заполнения
  void removeAwaitingPaymentDetails(String approvalId) {
    _awaitingPaymentDetailsIds.remove(approvalId);
    notifyListeners();
  }

  /// Запустить периодические запросы (каждые 2 минуты)
  void startPolling({String? businessId}) {
    // Останавливаем предыдущий таймер, если есть
    stopPolling();

    // Обновляем businessId ПЕРЕД запуском таймера
    _currentBusinessId = businessId;
    debugPrint('🚀 PendingConfirmationsProvider: Запуск polling для businessId: $_currentBusinessId');

    // Загружаем сразу все оповещения
    loadAll(businessId: businessId);

    // Запускаем периодические запросы каждые 2 минуты
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) {
        // Используем актуальное значение _currentBusinessId
        loadAll(businessId: _currentBusinessId);
      },
    );
  }

  /// Остановить периодические запросы
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Обновить businessId и перезапустить polling
  void updateBusinessId(String? businessId) {
    if (_currentBusinessId != businessId) {
      debugPrint('🔄 PendingConfirmationsProvider: Обновляем businessId с $_currentBusinessId на $businessId');
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
