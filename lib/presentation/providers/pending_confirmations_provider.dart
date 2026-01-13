import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/pending_confirmation.dart';
import '../../domain/usecases/get_pending_confirmations.dart';
import '../../domain/usecases/confirm_approval.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием pending confirmations
/// Автономно работает в фоне, делая запросы каждые 2 минуты
class PendingConfirmationsProvider with ChangeNotifier {
  final GetPendingConfirmations getPendingConfirmations;
  final ConfirmApproval confirmApproval;

  PendingConfirmationsProvider({
    required this.getPendingConfirmations,
    required this.confirmApproval,
  });

  List<PendingConfirmation> _pendingConfirmations = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  String? _currentBusinessId;

  /// Список pending confirmations
  List<PendingConfirmation> get pendingConfirmations => _pendingConfirmations;

  /// Количество pending confirmations
  int get count => _pendingConfirmations.length;

  /// Есть ли pending confirmations
  bool get hasPending => _pendingConfirmations.isNotEmpty;

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
        _error = _getErrorMessage(failure);
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

  /// Запустить периодические запросы (каждые 2 минуты)
  void startPolling({String? businessId}) {
    // Останавливаем предыдущий таймер, если есть
    stopPolling();

    _currentBusinessId = businessId;

    // Загружаем сразу
    loadPendingConfirmations(businessId: businessId);

    // Запускаем периодические запросы каждые 2 минуты
    _pollingTimer = Timer.periodic(
      const Duration(minutes: 2),
      (timer) {
        loadPendingConfirmations(businessId: _currentBusinessId);
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
      startPolling(businessId: businessId);
    }
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
