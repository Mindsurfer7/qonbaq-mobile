import '../entities/entity.dart';
import 'user.dart';
import 'customer_contact.dart';
import 'customer_observer.dart';

/// Тип клиента
enum CustomerType {
  individual,
  legalEntity,
}

/// Стадия воронки продаж
enum SalesFunnelStage {
  unprocessed,
  inProgress,
  interested,
  contractSigned,
  salesByContract,
  refused,
}

/// Доменная сущность клиента
class Customer extends Entity {
  final String id;
  final String businessId;
  final CustomerType customerType;

  // Основная идентификация
  final String? displayName;
  final String? name;

  // Для юрлиц
  final String? bin;
  final String? okpo;
  final String? fullNameKaz;
  final String? shortNameKaz;

  // Для физлиц (ИП)
  final String? iin;
  final String? firstName;
  final String? lastName;
  final String? patronymic;

  // Общие поля
  final String? type;
  final String? companySize;
  final String? industry;
  final double? annualTurnover;
  final String? currency;
  final String? logoUrl;

  // Воронка продаж
  final SalesFunnelStage? salesFunnelStage;
  final String? refusalReason;

  // Ответственные
  final String? responsibleId;
  final User? responsible;

  // Даты
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActivity;
  final DateTime? lastCommunication;
  final DateTime? contactCreatedAt;

  // Казахстан-специфичные поля
  final String? kbe;
  final String? headFullName;
  final String? headPosition;

  // UTM метки
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmContent;
  final String? utmTerm;

  // Дополнительно
  final String? comment;
  final String? contractNumber;
  final bool isKeyClient;
  final bool deletedIn1C;
  final bool createdFromCRMForm;

  // Связи
  final List<CustomerContact>? contacts;
  final List<CustomerObserver>? observers;

  const Customer({
    required this.id,
    required this.businessId,
    required this.customerType,
    this.displayName,
    this.name,
    this.bin,
    this.okpo,
    this.fullNameKaz,
    this.shortNameKaz,
    this.iin,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.type,
    this.companySize,
    this.industry,
    this.annualTurnover,
    this.currency,
    this.logoUrl,
    this.salesFunnelStage,
    this.refusalReason,
    this.responsibleId,
    this.responsible,
    required this.createdAt,
    required this.updatedAt,
    this.lastActivity,
    this.lastCommunication,
    this.contactCreatedAt,
    this.kbe,
    this.headFullName,
    this.headPosition,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmContent,
    this.utmTerm,
    this.comment,
    this.contractNumber,
    this.isKeyClient = false,
    this.deletedIn1C = false,
    this.createdFromCRMForm = false,
    this.contacts,
    this.observers,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Customer(id: $id, displayName: $displayName)';
}
