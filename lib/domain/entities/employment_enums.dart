/// Код организационной позиции
enum OrgPositionCode {
  /// Генеральный директор
  generalDirector,

  /// Заместитель генерального директора
  deputyGeneralDirector,

  /// Руководитель проекта(управления)
  projectManager,

  /// Руководитель отдела
  departmentHead,

  /// Должность работника
  employee,

  /// Гость
  guest,

  /// Финансовый директор
  financialDirector,

  /// Коммерческий директор
  commercialDirector,

  /// Технический директор
  technicalDirector,

  /// Директор по персоналу
  hrDirector,

  /// Главный бухгалтер
  chiefAccountant,
}

/// Расширение для конвертации enum в строку и обратно
extension OrgPositionCodeExtension on OrgPositionCode {
  /// Получить строковое значение для API
  String get code {
    switch (this) {
      case OrgPositionCode.generalDirector:
        return 'GENERAL_DIRECTOR';
      case OrgPositionCode.deputyGeneralDirector:
        return 'DEPUTY_GENERAL_DIRECTOR';
      case OrgPositionCode.projectManager:
        return 'PROJECT_MANAGER';
      case OrgPositionCode.departmentHead:
        return 'DEPARTMENT_HEAD';
      case OrgPositionCode.employee:
        return 'EMPLOYEE';
      case OrgPositionCode.guest:
        return 'GUEST';
      case OrgPositionCode.financialDirector:
        return 'FINANCIAL_DIRECTOR';
      case OrgPositionCode.commercialDirector:
        return 'COMMERCIAL_DIRECTOR';
      case OrgPositionCode.technicalDirector:
        return 'TECHNICAL_DIRECTOR';
      case OrgPositionCode.hrDirector:
        return 'HR_DIRECTOR';
      case OrgPositionCode.chiefAccountant:
        return 'CHIEF_ACCOUNTANT';
    }
  }

  /// Получить русское название
  String get nameRu {
    switch (this) {
      case OrgPositionCode.generalDirector:
        return 'Генеральный директор';
      case OrgPositionCode.deputyGeneralDirector:
        return 'Заместитель генерального директора';
      case OrgPositionCode.projectManager:
        return 'Руководитель проекта(управления)';
      case OrgPositionCode.departmentHead:
        return 'Руководитель отдела';
      case OrgPositionCode.employee:
        return 'Должность работника';
      case OrgPositionCode.guest:
        return 'Гость';
      case OrgPositionCode.financialDirector:
        return 'Финансовый директор';
      case OrgPositionCode.commercialDirector:
        return 'Коммерческий директор';
      case OrgPositionCode.technicalDirector:
        return 'Технический директор';
      case OrgPositionCode.hrDirector:
        return 'Директор по персоналу';
      case OrgPositionCode.chiefAccountant:
        return 'Главный бухгалтер';
    }
  }

  /// Создать enum из строки
  static OrgPositionCode? fromCode(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'GENERAL_DIRECTOR':
        return OrgPositionCode.generalDirector;
      case 'DEPUTY_GENERAL_DIRECTOR':
        return OrgPositionCode.deputyGeneralDirector;
      case 'PROJECT_MANAGER':
        return OrgPositionCode.projectManager;
      case 'DEPARTMENT_HEAD':
        return OrgPositionCode.departmentHead;
      case 'EMPLOYEE':
        return OrgPositionCode.employee;
      case 'GUEST':
        return OrgPositionCode.guest;
      case 'FINANCIAL_DIRECTOR':
        return OrgPositionCode.financialDirector;
      case 'COMMERCIAL_DIRECTOR':
        return OrgPositionCode.commercialDirector;
      case 'TECHNICAL_DIRECTOR':
        return OrgPositionCode.technicalDirector;
      case 'HR_DIRECTOR':
        return OrgPositionCode.hrDirector;
      case 'CHIEF_ACCOUNTANT':
        return OrgPositionCode.chiefAccountant;
      default:
        return null;
    }
  }
}

/// Код функциональной роли
enum RoleCode {
  /// Бухгалтер
  accountant,

  /// Юрист
  lawyer,

  /// Менеджер продаж
  salesManager,

  /// Менеджер закупа
  purchaseManager,

  /// Секретарь
  secretary,

  /// Маркетолог
  marketer,

  /// Менеджер по финансам
  financeManager,

  /// Логист
  logistician,

  /// Другое
  other,
}

/// Расширение для конвертации enum в строку и обратно
extension RoleCodeExtension on RoleCode {
  /// Получить строковое значение для API
  String get code {
    switch (this) {
      case RoleCode.accountant:
        return 'ACCOUNTANT';
      case RoleCode.lawyer:
        return 'LAWYER';
      case RoleCode.salesManager:
        return 'SALES_MANAGER';
      case RoleCode.purchaseManager:
        return 'PURCHASE_MANAGER';
      case RoleCode.secretary:
        return 'SECRETARY';
      case RoleCode.marketer:
        return 'MARKETER';
      case RoleCode.financeManager:
        return 'FINANCE_MANAGER';
      case RoleCode.logistician:
        return 'LOGISTICIAN';
      case RoleCode.other:
        return 'OTHER';
    }
  }

  /// Получить русское название
  String get nameRu {
    switch (this) {
      case RoleCode.accountant:
        return 'Бухгалтер';
      case RoleCode.lawyer:
        return 'Юрист';
      case RoleCode.salesManager:
        return 'Менеджер продаж';
      case RoleCode.purchaseManager:
        return 'Менеджер закупа';
      case RoleCode.secretary:
        return 'Секретарь';
      case RoleCode.marketer:
        return 'Маркетолог';
      case RoleCode.financeManager:
        return 'Менеджер по финансам';
      case RoleCode.logistician:
        return 'Логист';
      case RoleCode.other:
        return 'Другое';
    }
  }

  /// Создать enum из строки
  static RoleCode? fromCode(String? code) {
    if (code == null) return null;
    switch (code) {
      case 'ACCOUNTANT':
        return RoleCode.accountant;
      case 'LAWYER':
        return RoleCode.lawyer;
      case 'SALES_MANAGER':
        return RoleCode.salesManager;
      case 'PURCHASE_MANAGER':
        return RoleCode.purchaseManager;
      case 'SECRETARY':
        return RoleCode.secretary;
      case 'MARKETER':
        return RoleCode.marketer;
      case 'FINANCE_MANAGER':
        return RoleCode.financeManager;
      case 'LOGISTICIAN':
        return RoleCode.logistician;
      case 'OTHER':
        return RoleCode.other;
      default:
        return null;
    }
  }
}
