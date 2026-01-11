import '../entities/entity.dart';
import 'user_profile.dart';
import 'department.dart';
import 'project.dart';

/// Вид основного средства
enum AssetType {
  equipment,   // EQUIPMENT - Оборудование
  furniture,   // FURNITURE - Мебель
  officeTech,  // OFFICE_TECH - Орг.техника
  other,       // OTHER - Прочее
}

/// Состояние основного средства
enum AssetCondition {
  newUpTo3Months,  // NEW_UP_TO_3_MONTHS - Новое (до 3-х месяцев)
  good,            // GOOD - Хорошее
  satisfactory,    // SATISFACTORY - Удовлетворительное
  notWorking,      // NOT_WORKING - Не рабочее
  writtenOff,      // WRITTEN_OFF - Списано по акту
}

/// Передача актива (владелец)
class AssetTransfer extends Entity {
  final String id;
  final String assetId;
  final String? fromUserId;
  final String toUserId;
  final DateTime transferDate;
  final String? reason;
  final String? comment;
  final String createdBy;
  
  // Вложенные данные
  final ProfileUser? fromUser;
  final ProfileUser toUser;

  const AssetTransfer({
    required this.id,
    required this.assetId,
    this.fromUserId,
    required this.toUserId,
    required this.transferDate,
    this.reason,
    this.comment,
    required this.createdBy,
    this.fromUser,
    required this.toUser,
  });
}

/// Ремонт актива
class AssetRepair extends Entity {
  final String id;
  final String assetId;
  final DateTime repairDate;
  final String repairType;
  final double cost;
  final String? description;
  final String createdBy;

  const AssetRepair({
    required this.id,
    required this.assetId,
    required this.repairDate,
    required this.repairType,
    required this.cost,
    this.description,
    required this.createdBy,
  });
}

/// Инвентаризация актива
class AssetInventory extends Entity {
  final String id;
  final String assetId;
  final DateTime inventoryDate;
  final String? status;
  final String? comment;
  final String conductedBy;

  const AssetInventory({
    required this.id,
    required this.assetId,
    required this.inventoryDate,
    this.status,
    this.comment,
    required this.conductedBy,
  });
}

/// Фото актива
class AssetPhoto extends Entity {
  final String id;
  final String assetId;
  final String fileUrl;
  final String? fileName;
  final String? fileType;
  final bool isInventoryPhoto;
  final String? inventoryId;

  const AssetPhoto({
    required this.id,
    required this.assetId,
    required this.fileUrl,
    this.fileName,
    this.fileType,
    this.isInventoryPhoto = false,
    this.inventoryId,
  });
}

/// Списание актива
class AssetWriteOff extends Entity {
  final String id;
  final String assetId;
  final DateTime writeOffDate;
  final String reason;
  final double? writeOffAmount;
  final String? documentUrl;

  const AssetWriteOff({
    required this.id,
    required this.assetId,
    required this.writeOffDate,
    required this.reason,
    this.writeOffAmount,
    this.documentUrl,
  });
}

/// Доменная сущность основного средства
class FixedAsset extends Entity {
  final String id;
  final String businessId;
  final String? projectId;
  final String name;
  final String? model;
  final AssetType type;
  final String? inventoryNumber;
  final String? serialNumber;
  final String? locationCity;
  final String? locationAddress;
  final AssetCondition condition;
  final String? departmentId;
  final String currentOwnerId;
  final DateTime creationDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  
  // Вложенные данные (могут отсутствовать в кратком списке)
  final ProfileUser? currentOwner;
  final DepartmentInfo? department;
  final Project? project;
  
  // Статистика
  final int? repairsCount;
  final int? photosCount;
  final int? tasksCount;
  
  // Детальные данные (для детальной страницы)
  final AssetWriteOff? writeOff;
  final List<AssetTransfer>? transfers;
  final List<AssetRepair>? repairs;
  final List<AssetPhoto>? photos;
  final List<AssetInventory>? inventories;
  final double? repairsTotal;

  const FixedAsset({
    required this.id,
    required this.businessId,
    this.projectId,
    required this.name,
    this.model,
    required this.type,
    this.inventoryNumber,
    this.serialNumber,
    this.locationCity,
    this.locationAddress,
    required this.condition,
    this.departmentId,
    required this.currentOwnerId,
    required this.creationDate,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
    this.currentOwner,
    this.department,
    this.project,
    this.repairsCount,
    this.photosCount,
    this.tasksCount,
    this.writeOff,
    this.transfers,
    this.repairs,
    this.photos,
    this.inventories,
    this.repairsTotal,
  });
}
