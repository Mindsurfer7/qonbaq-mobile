import '../../domain/entities/customer.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/entities/customer_observer.dart';
import '../models/model.dart';
import 'customer_contact_model.dart';
import 'customer_observer_model.dart';

/// Модель клиента
class CustomerModel extends Customer implements Model {
  const CustomerModel({
    required super.id,
    required super.businessId,
    required super.customerType,
    super.displayName,
    super.name,
    super.bin,
    super.okpo,
    super.fullNameKaz,
    super.shortNameKaz,
    super.iin,
    super.firstName,
    super.lastName,
    super.patronymic,
    super.type,
    super.companySize,
    super.industry,
    super.annualTurnover,
    super.currency,
    super.logoUrl,
    super.salesFunnelStage,
    super.refusalReason,
    super.responsibleId,
    super.responsible,
    required super.createdAt,
    required super.updatedAt,
    super.lastActivity,
    super.lastCommunication,
    super.contactCreatedAt,
    super.kbe,
    super.headFullName,
    super.headPosition,
    super.utmSource,
    super.utmMedium,
    super.utmCampaign,
    super.utmContent,
    super.utmTerm,
    super.comment,
    super.contractNumber,
    super.isKeyClient,
    super.deletedIn1C,
    super.createdFromCRMForm,
    super.contacts,
    super.observers,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    // Парсинг responsible
    User? responsible;
    if (json['responsible'] != null) {
      final responsibleJson = json['responsible'] as Map<String, dynamic>;
      responsible = User(
        id: responsibleJson['id'] as String,
        name: responsibleJson['firstName'] != null && responsibleJson['lastName'] != null
            ? '${responsibleJson['firstName']} ${responsibleJson['lastName']}'
            : responsibleJson['email'] as String? ?? '',
        email: responsibleJson['email'] as String,
      );
    }

    // Парсинг contacts
    List<CustomerContact>? contacts;
    if (json['contacts'] != null) {
      final contactsList = json['contacts'] as List<dynamic>;
      contacts = contactsList
          .map((contactJson) => CustomerContactModel.fromJson(contactJson as Map<String, dynamic>).toEntity())
          .toList();
    }

    // Парсинг observers
    List<CustomerObserver>? observers;
    if (json['observers'] != null) {
      final observersList = json['observers'] as List<dynamic>;
      observers = observersList
          .map((observerJson) => CustomerObserverModel.fromJson(observerJson as Map<String, dynamic>).toEntity())
          .toList();
    }

    return CustomerModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      customerType: _parseCustomerType(json['customerType'] as String),
      displayName: json['displayName'] as String?,
      name: json['name'] as String?,
      bin: json['bin'] as String?,
      okpo: json['okpo'] as String?,
      fullNameKaz: json['fullNameKaz'] as String?,
      shortNameKaz: json['shortNameKaz'] as String?,
      iin: json['iin'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      patronymic: json['patronymic'] as String?,
      type: json['type'] as String?,
      companySize: json['companySize'] as String?,
      industry: json['industry'] as String?,
      annualTurnover: json['annualTurnover'] != null
          ? (json['annualTurnover'] as num).toDouble()
          : null,
      currency: json['currency'] as String?,
      logoUrl: json['logoUrl'] as String?,
      salesFunnelStage: json['salesFunnelStage'] != null
          ? _parseSalesFunnelStage(json['salesFunnelStage'] as String)
          : null,
      refusalReason: json['refusalReason'] as String?,
      responsibleId: json['responsibleId'] as String?,
      responsible: responsible,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'] as String)
          : null,
      lastCommunication: json['lastCommunication'] != null
          ? DateTime.parse(json['lastCommunication'] as String)
          : null,
      contactCreatedAt: json['contactCreatedAt'] != null
          ? DateTime.parse(json['contactCreatedAt'] as String)
          : null,
      kbe: json['kbe'] as String?,
      headFullName: json['headFullName'] as String?,
      headPosition: json['headPosition'] as String?,
      utmSource: json['utmSource'] as String?,
      utmMedium: json['utmMedium'] as String?,
      utmCampaign: json['utmCampaign'] as String?,
      utmContent: json['utmContent'] as String?,
      utmTerm: json['utmTerm'] as String?,
      comment: json['comment'] as String?,
      contractNumber: json['contractNumber'] as String?,
      isKeyClient: json['isKeyClient'] as bool? ?? false,
      deletedIn1C: json['deletedIn1C'] as bool? ?? false,
      createdFromCRMForm: json['createdFromCRMForm'] as bool? ?? false,
      contacts: contacts,
      observers: observers,
    );
  }

  static CustomerType _parseCustomerType(String type) {
    switch (type.toUpperCase()) {
      case 'INDIVIDUAL':
        return CustomerType.individual;
      case 'LEGAL_ENTITY':
        return CustomerType.legalEntity;
      default:
        return CustomerType.legalEntity;
    }
  }

  static String _customerTypeToString(CustomerType type) {
    switch (type) {
      case CustomerType.individual:
        return 'INDIVIDUAL';
      case CustomerType.legalEntity:
        return 'LEGAL_ENTITY';
    }
  }

  static SalesFunnelStage _parseSalesFunnelStage(String stage) {
    switch (stage.toUpperCase()) {
      case 'UNPROCESSED':
        return SalesFunnelStage.unprocessed;
      case 'IN_PROGRESS':
        return SalesFunnelStage.inProgress;
      case 'INTERESTED':
        return SalesFunnelStage.interested;
      case 'CONTRACT_SIGNED':
        return SalesFunnelStage.contractSigned;
      case 'SALES_BY_CONTRACT':
        return SalesFunnelStage.salesByContract;
      case 'REFUSED':
        return SalesFunnelStage.refused;
      default:
        return SalesFunnelStage.unprocessed;
    }
  }

  static String? _salesFunnelStageToString(SalesFunnelStage? stage) {
    if (stage == null) return null;
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return 'UNPROCESSED';
      case SalesFunnelStage.inProgress:
        return 'IN_PROGRESS';
      case SalesFunnelStage.interested:
        return 'INTERESTED';
      case SalesFunnelStage.contractSigned:
        return 'CONTRACT_SIGNED';
      case SalesFunnelStage.salesByContract:
        return 'SALES_BY_CONTRACT';
      case SalesFunnelStage.refused:
        return 'REFUSED';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerType': _customerTypeToString(customerType),
      if (displayName != null) 'displayName': displayName,
      if (name != null) 'name': name,
      if (bin != null) 'bin': bin,
      if (okpo != null) 'okpo': okpo,
      if (fullNameKaz != null) 'fullNameKaz': fullNameKaz,
      if (shortNameKaz != null) 'shortNameKaz': shortNameKaz,
      if (iin != null) 'iin': iin,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (patronymic != null) 'patronymic': patronymic,
      if (type != null) 'type': type,
      if (companySize != null) 'companySize': companySize,
      if (industry != null) 'industry': industry,
      if (annualTurnover != null) 'annualTurnover': annualTurnover,
      if (currency != null) 'currency': currency,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (salesFunnelStage != null) 'salesFunnelStage': _salesFunnelStageToString(salesFunnelStage),
      if (refusalReason != null) 'refusalReason': refusalReason,
      if (responsibleId != null) 'responsibleId': responsibleId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (lastActivity != null) 'lastActivity': lastActivity!.toIso8601String(),
      if (lastCommunication != null) 'lastCommunication': lastCommunication!.toIso8601String(),
      if (contactCreatedAt != null) 'contactCreatedAt': contactCreatedAt!.toIso8601String(),
      if (kbe != null) 'kbe': kbe,
      if (headFullName != null) 'headFullName': headFullName,
      if (headPosition != null) 'headPosition': headPosition,
      if (utmSource != null) 'utmSource': utmSource,
      if (utmMedium != null) 'utmMedium': utmMedium,
      if (utmCampaign != null) 'utmCampaign': utmCampaign,
      if (utmContent != null) 'utmContent': utmContent,
      if (utmTerm != null) 'utmTerm': utmTerm,
      if (comment != null) 'comment': comment,
      if (contractNumber != null) 'contractNumber': contractNumber,
      'isKeyClient': isKeyClient,
      'deletedIn1C': deletedIn1C,
      'createdFromCRMForm': createdFromCRMForm,
    };
  }

  /// Преобразование в JSON для создания клиента
  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      'customerType': _customerTypeToString(customerType),
      if (displayName != null && displayName!.isNotEmpty) 'displayName': displayName,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (bin != null && bin!.isNotEmpty) 'bin': bin,
      if (okpo != null && okpo!.isNotEmpty) 'okpo': okpo,
      if (fullNameKaz != null && fullNameKaz!.isNotEmpty) 'fullNameKaz': fullNameKaz,
      if (shortNameKaz != null && shortNameKaz!.isNotEmpty) 'shortNameKaz': shortNameKaz,
      if (iin != null && iin!.isNotEmpty) 'iin': iin,
      if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
      if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
      if (patronymic != null && patronymic!.isNotEmpty) 'patronymic': patronymic,
      if (type != null && type!.isNotEmpty) 'type': type,
      if (companySize != null && companySize!.isNotEmpty) 'companySize': companySize,
      if (industry != null && industry!.isNotEmpty) 'industry': industry,
      if (annualTurnover != null) 'annualTurnover': annualTurnover,
      if (currency != null && currency!.isNotEmpty) 'currency': currency,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (salesFunnelStage != null) 'salesFunnelStage': _salesFunnelStageToString(salesFunnelStage),
      if (responsibleId != null && responsibleId!.isNotEmpty) 'responsibleId': responsibleId,
      if (kbe != null && kbe!.isNotEmpty) 'kbe': kbe,
      if (headFullName != null && headFullName!.isNotEmpty) 'headFullName': headFullName,
      if (headPosition != null && headPosition!.isNotEmpty) 'headPosition': headPosition,
      if (utmSource != null && utmSource!.isNotEmpty) 'utmSource': utmSource,
      if (utmMedium != null && utmMedium!.isNotEmpty) 'utmMedium': utmMedium,
      if (utmCampaign != null && utmCampaign!.isNotEmpty) 'utmCampaign': utmCampaign,
      if (utmContent != null && utmContent!.isNotEmpty) 'utmContent': utmContent,
      if (utmTerm != null && utmTerm!.isNotEmpty) 'utmTerm': utmTerm,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (contractNumber != null && contractNumber!.isNotEmpty) 'contractNumber': contractNumber,
      if (isKeyClient) 'isKeyClient': isKeyClient,
      if (createdFromCRMForm) 'createdFromCRMForm': createdFromCRMForm,
    };
  }

  /// Преобразование в JSON для обновления клиента
  Map<String, dynamic> toUpdateJson() {
    return {
      if (displayName != null && displayName!.isNotEmpty) 'displayName': displayName,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (bin != null && bin!.isNotEmpty) 'bin': bin,
      if (okpo != null && okpo!.isNotEmpty) 'okpo': okpo,
      if (fullNameKaz != null && fullNameKaz!.isNotEmpty) 'fullNameKaz': fullNameKaz,
      if (shortNameKaz != null && shortNameKaz!.isNotEmpty) 'shortNameKaz': shortNameKaz,
      if (iin != null && iin!.isNotEmpty) 'iin': iin,
      if (firstName != null && firstName!.isNotEmpty) 'firstName': firstName,
      if (lastName != null && lastName!.isNotEmpty) 'lastName': lastName,
      if (patronymic != null && patronymic!.isNotEmpty) 'patronymic': patronymic,
      if (type != null && type!.isNotEmpty) 'type': type,
      if (companySize != null && companySize!.isNotEmpty) 'companySize': companySize,
      if (industry != null && industry!.isNotEmpty) 'industry': industry,
      if (annualTurnover != null) 'annualTurnover': annualTurnover,
      if (currency != null && currency!.isNotEmpty) 'currency': currency,
      if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl,
      if (salesFunnelStage != null) 'salesFunnelStage': _salesFunnelStageToString(salesFunnelStage),
      if (refusalReason != null && refusalReason!.isNotEmpty) 'refusalReason': refusalReason,
      if (responsibleId != null && responsibleId!.isNotEmpty) 'responsibleId': responsibleId,
      if (kbe != null && kbe!.isNotEmpty) 'kbe': kbe,
      if (headFullName != null && headFullName!.isNotEmpty) 'headFullName': headFullName,
      if (headPosition != null && headPosition!.isNotEmpty) 'headPosition': headPosition,
      if (utmSource != null && utmSource!.isNotEmpty) 'utmSource': utmSource,
      if (utmMedium != null && utmMedium!.isNotEmpty) 'utmMedium': utmMedium,
      if (utmCampaign != null && utmCampaign!.isNotEmpty) 'utmCampaign': utmCampaign,
      if (utmContent != null && utmContent!.isNotEmpty) 'utmContent': utmContent,
      if (utmTerm != null && utmTerm!.isNotEmpty) 'utmTerm': utmTerm,
      if (comment != null && comment!.isNotEmpty) 'comment': comment,
      if (contractNumber != null && contractNumber!.isNotEmpty) 'contractNumber': contractNumber,
      if (isKeyClient) 'isKeyClient': isKeyClient,
    };
  }

  Customer toEntity() {
    return Customer(
      id: id,
      businessId: businessId,
      customerType: customerType,
      displayName: displayName,
      name: name,
      bin: bin,
      okpo: okpo,
      fullNameKaz: fullNameKaz,
      shortNameKaz: shortNameKaz,
      iin: iin,
      firstName: firstName,
      lastName: lastName,
      patronymic: patronymic,
      type: type,
      companySize: companySize,
      industry: industry,
      annualTurnover: annualTurnover,
      currency: currency,
      logoUrl: logoUrl,
      salesFunnelStage: salesFunnelStage,
      refusalReason: refusalReason,
      responsibleId: responsibleId,
      responsible: responsible,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastActivity: lastActivity,
      lastCommunication: lastCommunication,
      contactCreatedAt: contactCreatedAt,
      kbe: kbe,
      headFullName: headFullName,
      headPosition: headPosition,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
      utmContent: utmContent,
      utmTerm: utmTerm,
      comment: comment,
      contractNumber: contractNumber,
      isKeyClient: isKeyClient,
      deletedIn1C: deletedIn1C,
      createdFromCRMForm: createdFromCRMForm,
      contacts: contacts,
      observers: observers,
    );
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      businessId: customer.businessId,
      customerType: customer.customerType,
      displayName: customer.displayName,
      name: customer.name,
      bin: customer.bin,
      okpo: customer.okpo,
      fullNameKaz: customer.fullNameKaz,
      shortNameKaz: customer.shortNameKaz,
      iin: customer.iin,
      firstName: customer.firstName,
      lastName: customer.lastName,
      patronymic: customer.patronymic,
      type: customer.type,
      companySize: customer.companySize,
      industry: customer.industry,
      annualTurnover: customer.annualTurnover,
      currency: customer.currency,
      logoUrl: customer.logoUrl,
      salesFunnelStage: customer.salesFunnelStage,
      refusalReason: customer.refusalReason,
      responsibleId: customer.responsibleId,
      responsible: customer.responsible,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
      lastActivity: customer.lastActivity,
      lastCommunication: customer.lastCommunication,
      contactCreatedAt: customer.contactCreatedAt,
      kbe: customer.kbe,
      headFullName: customer.headFullName,
      headPosition: customer.headPosition,
      utmSource: customer.utmSource,
      utmMedium: customer.utmMedium,
      utmCampaign: customer.utmCampaign,
      utmContent: customer.utmContent,
      utmTerm: customer.utmTerm,
      comment: customer.comment,
      contractNumber: customer.contractNumber,
      isKeyClient: customer.isKeyClient,
      deletedIn1C: customer.deletedIn1C,
      createdFromCRMForm: customer.createdFromCRMForm,
      contacts: customer.contacts,
      observers: customer.observers,
    );
  }
}
