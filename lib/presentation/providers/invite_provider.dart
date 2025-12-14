import 'package:flutter/foundation.dart';
import '../../domain/entities/invite.dart';
import '../../domain/usecases/create_invite.dart';
import '../../domain/usecases/get_current_invite.dart';
import '../../core/error/failures.dart';
import '../../core/usecase/usecase.dart';

/// Провайдер для управления состоянием приглашений
class InviteProvider with ChangeNotifier {
  final CreateInvite createInvite;
  final GetCurrentInvite getCurrentInvite;

  InviteProvider({
    required this.createInvite,
    required this.getCurrentInvite,
  });

  CreateInviteResult? _inviteResult;
  bool _isLoading = false;
  String? _error;

  /// Результат создания приглашения
  CreateInviteResult? get inviteResult => _inviteResult;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Создать приглашение
  Future<void> createInviteLink({
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    _isLoading = true;
    _error = null;
    _inviteResult = null;
    notifyListeners();

    final result = await createInvite.call(
      CreateInviteParams(
        maxUses: maxUses,
        expiresAt: expiresAt,
      ),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (result) {
        _inviteResult = result;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Загрузить текущий активный инвайт
  Future<void> loadCurrentInvite() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getCurrentInvite.call(NoParams());

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (result) {
        _inviteResult = result; // Может быть null, если активного инвайта нет
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Сбросить состояние
  void reset() {
    _inviteResult = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Получить сообщение об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}

