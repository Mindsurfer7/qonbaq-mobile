import '../../domain/entities/customer_contact.dart';
import '../models/model.dart';

/// Модель контакта клиента
class CustomerContactModel extends CustomerContact implements Model {
  const CustomerContactModel({
    required super.id,
    required super.customerId,
    required super.type,
    required super.value,
    super.label,
    super.isPrimary,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerContactModel.fromJson(Map<String, dynamic> json) {
    return CustomerContactModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      type: _parseContactType(json['type'] as String),
      value: json['value'] as String,
      label: json['label'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static CustomerContactType _parseContactType(String type) {
    switch (type.toUpperCase()) {
      // Телефоны
      case 'PHONE_WORK':
        return CustomerContactType.phoneWork;
      case 'PHONE_MOBILE':
        return CustomerContactType.phoneMobile;
      case 'PHONE_FAX':
        return CustomerContactType.phoneFax;
      case 'PHONE_HOME':
        return CustomerContactType.phoneHome;
      case 'PHONE_PAGER':
        return CustomerContactType.phonePager;
      case 'PHONE_NEWSLETTER':
        return CustomerContactType.phoneNewsletter;
      case 'PHONE_OTHER':
        return CustomerContactType.phoneOther;
      // Email
      case 'EMAIL_WORK':
        return CustomerContactType.emailWork;
      case 'EMAIL_PERSONAL':
        return CustomerContactType.emailPersonal;
      case 'EMAIL_NEWSLETTER':
        return CustomerContactType.emailNewsletter;
      case 'EMAIL_OTHER':
        return CustomerContactType.emailOther;
      // Сайты
      case 'WEBSITE_CORP':
        return CustomerContactType.websiteCorp;
      case 'WEBSITE_PERSONAL':
        return CustomerContactType.websitePersonal;
      // Соцсети
      case 'SOCIAL_FACEBOOK':
        return CustomerContactType.socialFacebook;
      case 'SOCIAL_VK':
        return CustomerContactType.socialVk;
      case 'SOCIAL_INSTAGRAM':
        return CustomerContactType.socialInstagram;
      case 'SOCIAL_TELEGRAM':
        return CustomerContactType.socialTelegram;
      case 'SOCIAL_TELEGRAM_ID':
        return CustomerContactType.socialTelegramId;
      case 'SOCIAL_VIBER':
        return CustomerContactType.socialViber;
      case 'SOCIAL_TWITTER':
        return CustomerContactType.socialTwitter;
      case 'SOCIAL_LIVEJOURNAL':
        return CustomerContactType.socialLivejournal;
      case 'SOCIAL_AVITO':
        return CustomerContactType.socialAvito;
      // Другое
      case 'OTHER':
        return CustomerContactType.other;
      default:
        return CustomerContactType.other;
    }
  }

  static String _contactTypeToString(CustomerContactType type) {
    switch (type) {
      // Телефоны
      case CustomerContactType.phoneWork:
        return 'PHONE_WORK';
      case CustomerContactType.phoneMobile:
        return 'PHONE_MOBILE';
      case CustomerContactType.phoneFax:
        return 'PHONE_FAX';
      case CustomerContactType.phoneHome:
        return 'PHONE_HOME';
      case CustomerContactType.phonePager:
        return 'PHONE_PAGER';
      case CustomerContactType.phoneNewsletter:
        return 'PHONE_NEWSLETTER';
      case CustomerContactType.phoneOther:
        return 'PHONE_OTHER';
      // Email
      case CustomerContactType.emailWork:
        return 'EMAIL_WORK';
      case CustomerContactType.emailPersonal:
        return 'EMAIL_PERSONAL';
      case CustomerContactType.emailNewsletter:
        return 'EMAIL_NEWSLETTER';
      case CustomerContactType.emailOther:
        return 'EMAIL_OTHER';
      // Сайты
      case CustomerContactType.websiteCorp:
        return 'WEBSITE_CORP';
      case CustomerContactType.websitePersonal:
        return 'WEBSITE_PERSONAL';
      // Соцсети
      case CustomerContactType.socialFacebook:
        return 'SOCIAL_FACEBOOK';
      case CustomerContactType.socialVk:
        return 'SOCIAL_VK';
      case CustomerContactType.socialInstagram:
        return 'SOCIAL_INSTAGRAM';
      case CustomerContactType.socialTelegram:
        return 'SOCIAL_TELEGRAM';
      case CustomerContactType.socialTelegramId:
        return 'SOCIAL_TELEGRAM_ID';
      case CustomerContactType.socialViber:
        return 'SOCIAL_VIBER';
      case CustomerContactType.socialTwitter:
        return 'SOCIAL_TWITTER';
      case CustomerContactType.socialLivejournal:
        return 'SOCIAL_LIVEJOURNAL';
      case CustomerContactType.socialAvito:
        return 'SOCIAL_AVITO';
      // Другое
      case CustomerContactType.other:
        return 'OTHER';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'type': _contactTypeToString(type),
      'value': value,
      if (label != null) 'label': label,
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания контакта
  Map<String, dynamic> toCreateJson() {
    return {
      'customerId': customerId,
      'type': _contactTypeToString(type),
      'value': value,
      if (label != null && label!.isNotEmpty) 'label': label,
      'isPrimary': isPrimary,
    };
  }

  /// Преобразование в JSON для обновления контакта
  Map<String, dynamic> toUpdateJson() {
    return {
      if (type != CustomerContactType.other) 'type': _contactTypeToString(type),
      if (value.isNotEmpty) 'value': value,
      if (label != null && label!.isNotEmpty) 'label': label,
      'isPrimary': isPrimary,
    };
  }

  CustomerContact toEntity() {
    return CustomerContact(
      id: id,
      customerId: customerId,
      type: type,
      value: value,
      label: label,
      isPrimary: isPrimary,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory CustomerContactModel.fromEntity(CustomerContact contact) {
    return CustomerContactModel(
      id: contact.id,
      customerId: contact.customerId,
      type: contact.type,
      value: contact.value,
      label: contact.label,
      isPrimary: contact.isPrimary,
      createdAt: contact.createdAt,
      updatedAt: contact.updatedAt,
    );
  }
}
