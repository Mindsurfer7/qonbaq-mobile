import 'package:flutter/foundation.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/usecases/login_user.dart';
import '../../core/error/failures.dart';
import '../../core/utils/token_storage.dart';

/// Провайдер для управления состоянием аутентификации
class AuthProvider with ChangeNotifier {
  final RegisterUser registerUser;
  final LoginUser loginUser;

  AuthProvider({required this.registerUser, required this.loginUser});

  AuthUser? _user;
  bool _isLoading = false;
  String? _error;

  /// Текущий пользователь
  AuthUser? get user => _user;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Проверка авторизации
  bool get isAuthenticated => _user != null;

  /// Регистрация пользователя
  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? inviteCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await registerUser.call(
      RegisterParams(
        email: email,
        username: username,
        password: password,
        inviteCode: inviteCode,
      ),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (user) {
        _user = user;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Вход пользователя
  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await loginUser.call(
      LoginParams(email: email, password: password),
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        notifyListeners();
        return false;
      },
      (user) {
        _user = user;
        _error = null;
        notifyListeners();
        return true;
      },
    );
  }

  /// Выход пользователя
  Future<void> logout() async {
    _user = null;
    _error = null;
    // Очищаем токены
    await TokenStorage.instance.clearTokens();
    notifyListeners();
  }

  /// Очистка ошибки
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Получение сообщения об ошибке
  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    } else if (failure is GeneralFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }
}
