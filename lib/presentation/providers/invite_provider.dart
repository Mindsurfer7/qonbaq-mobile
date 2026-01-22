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

  InvitesList? _invitesList;
  bool _isLoading = false;
  String? _error;

  /// Список инвайтов
  InvitesList? get invitesList => _invitesList;

  /// Получить инвайт по типу
  InviteWithLinks? getInviteByType(InviteType type) {
    return _invitesList?.getInviteByType(type);
  }

  /// Получить FAMILY инвайт
  InviteWithLinks? get familyInvite => getInviteByType(InviteType.family);

  /// Получить BUSINESS инвайт
  InviteWithLinks? get businessInvite => getInviteByType(InviteType.business);

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Есть ли у пользователя бизнес (если есть BUSINESS инвайт)
  bool get hasBusiness => _invitesList?.hasBusiness ?? false;

  /// Результат создания приглашения (для обратной совместимости)
  /// Возвращает FAMILY инвайт, если есть, иначе первый доступный
  CreateInviteResult? get inviteResult {
    if (_invitesList == null || _invitesList!.invites.isEmpty) {
      return null;
    }
    final invite = familyInvite ?? _invitesList!.invites.first;
    return CreateInviteResult(
      invite: invite.invite,
      links: invite.links,
      hasBusiness: hasBusiness,
    );
  }

  /// Создать приглашение
  Future<void> createInviteLink({
    String? inviteType,
    int? maxUses,
    DateTime? expiresAt,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createInvite.call(
      CreateInviteParams(
        inviteType: inviteType,
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
        _invitesList = result;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Загрузить текущие инвайты
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
        _invitesList = result; // Может быть null, если инвайтов нет
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Сбросить состояние
  void reset() {
    _invitesList = null;
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

