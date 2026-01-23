import '../entities/entity.dart';

/// Тип контакта клиента
enum CustomerContactType {
  // Телефоны
  phoneWork,
  phoneMobile,
  phoneFax,
  phoneHome,
  phonePager,
  phoneNewsletter,
  phoneOther,
  // Email
  emailWork,
  emailPersonal,
  emailNewsletter,
  emailOther,
  // Сайты
  websiteCorp,
  websitePersonal,
  // Соцсети
  socialFacebook,
  socialVk,
  socialInstagram,
  socialTelegram,
  socialTelegramId,
  socialViber,
  socialTwitter,
  socialLivejournal,
  socialAvito,
  // Другое
  other,
}

/// Доменная сущность контакта клиента
class CustomerContact extends Entity {
  final String id;
  final String customerId;
  final CustomerContactType type;
  final String value;
  final String? label;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerContact({
    required this.id,
    required this.customerId,
    required this.type,
    required this.value,
    this.label,
    this.isPrimary = false,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerContact &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'CustomerContact(id: $id, type: $type, value: $value)';
}
