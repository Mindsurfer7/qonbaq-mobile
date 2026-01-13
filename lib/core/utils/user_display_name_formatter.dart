import '../../domain/entities/user_profile.dart';

/// Утилиты для форматирования имени пользователя
class UserDisplayNameFormatter {
  /// Форматирует имя пользователя в читаемый вид
  /// Возвращает "Фамилия Имя Отчество" или email, если имя отсутствует
  static String getUserDisplayName(ProfileUser user) {
    final parts = <String>[];
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      parts.add(user.firstName!);
    }
    if (user.patronymic != null && user.patronymic!.isNotEmpty) {
      parts.add(user.patronymic!);
    }
    return parts.isEmpty ? user.email : parts.join(' ');
  }
}
