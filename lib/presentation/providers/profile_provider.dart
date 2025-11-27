import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/business.dart';
import '../../domain/usecases/get_user_businesses.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../core/error/failures.dart';

/// Провайдер для управления состоянием профиля пользователя
class ProfileProvider with ChangeNotifier {
  final GetUserBusinesses getUserBusinesses;
  final GetUserProfile getUserProfile;

  ProfileProvider({
    required this.getUserBusinesses,
    required this.getUserProfile,
  });

  List<Business>? _businesses;
  UserProfile? _profile;
  Business? _selectedBusiness;
  bool _isLoading = false;
  String? _error;

  /// Список компаний
  List<Business>? get businesses => _businesses;

  /// Профиль пользователя
  UserProfile? get profile => _profile;

  /// Выбранная компания
  Business? get selectedBusiness => _selectedBusiness;

  /// Статус загрузки
  bool get isLoading => _isLoading;

  /// Сообщение об ошибке
  String? get error => _error;

  /// Загрузить список компаний
  Future<void> loadBusinesses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getUserBusinesses.call();
    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (businesses) {
        _businesses = businesses;
        if (businesses.isNotEmpty) {
          _selectedBusiness = businesses.first;
          loadProfile();
        } else {
          _isLoading = false;
          notifyListeners();
        }
      },
    );
  }

  /// Загрузить профиль пользователя
  Future<void> loadProfile() async {
    if (_selectedBusiness == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getUserProfile.call(
      GetUserProfileParams(businessId: _selectedBusiness!.id),
    );

    result.fold(
      (failure) {
        _error = _getErrorMessage(failure);
        _isLoading = false;
        notifyListeners();
      },
      (profile) {
        _profile = profile;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
    );
  }

  /// Выбрать компанию
  void selectBusiness(Business business) {
    if (_selectedBusiness?.id == business.id) return;

    _selectedBusiness = business;
    _profile = null;
    notifyListeners();
    loadProfile();
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


