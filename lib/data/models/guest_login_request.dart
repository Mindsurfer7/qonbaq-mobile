import '../models/model.dart';

/// Модель запроса гостевого логина
class GuestLoginRequest implements Model {
  final String guestUuid;

  GuestLoginRequest({required this.guestUuid});

  @override
  Map<String, dynamic> toJson() {
    return {'guestUuid': guestUuid};
  }

  /// Валидация UUID
  String? validate() {
    if (guestUuid.isEmpty) {
      return 'guestUuid обязателен';
    }
    // Проверка формата UUID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    if (!uuidRegex.hasMatch(guestUuid)) {
      return 'Неверный формат UUID';
    }
    return null;
  }
}
