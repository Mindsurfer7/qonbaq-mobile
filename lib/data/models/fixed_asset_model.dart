import '../../domain/entities/fixed_asset.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/project.dart';
import '../models/model.dart';

/// Модель основного средства
class FixedAssetModel extends FixedAsset implements Model {
  const FixedAssetModel({
    required super.id,
    required super.businessId,
    super.projectId,
    required super.name,
    super.model,
    required super.type,
    super.inventoryNumber,
    super.serialNumber,
    super.locationCity,
    super.locationAddress,
    required super.condition,
    super.departmentId,
    required super.currentOwnerId,
    required super.creationDate,
    required super.createdAt,
    required super.updatedAt,
    super.archivedAt,
    super.currentOwner,
    super.department,
    super.project,
    super.repairsCount,
    super.photosCount,
    super.tasksCount,
    super.writeOff,
    super.transfers,
    super.repairs,
    super.photos,
    super.inventories,
    super.repairsTotal,
  });

  factory FixedAssetModel.fromJson(Map<String, dynamic> json) {
    // Парсинг текущего владельца
    ProfileUser? currentOwner;
    if (json['currentOwner'] != null) {
      final ownerJson = json['currentOwner'] as Map<String, dynamic>;
      currentOwner = ProfileUser(
        id: ownerJson['id'] as String,
        email: ownerJson['email'] as String? ?? '',
        firstName: ownerJson['firstName'] as String?,
        lastName: ownerJson['lastName'] as String?,
        patronymic: ownerJson['patronymic'] as String?,
        phone: ownerJson['phone'] as String?,
      );
    }

    // Парсинг департамента
    DepartmentInfo? department;
    if (json['department'] != null) {
      final deptJson = json['department'] as Map<String, dynamic>;
      department = DepartmentInfo(
        id: deptJson['id'] as String,
        name: deptJson['name'] as String,
        description: deptJson['description'] as String?,
      );
    }

    // Парсинг проекта
    Project? project;
    if (json['project'] != null) {
      final projectJson = json['project'] as Map<String, dynamic>;
      project = Project(
        id: projectJson['id'] as String,
        name: projectJson['name'] as String,
        description: projectJson['description'] as String?,
        businessId: projectJson['businessId'] as String? ?? json['businessId'] as String,
        city: projectJson['city'] as String?,
        country: projectJson['country'] as String?,
        address: projectJson['address'] as String?,
        isActive: projectJson['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(projectJson['createdAt'] as String),
        updatedAt: DateTime.parse(projectJson['updatedAt'] as String),
      );
    }

    // Парсинг списания
    AssetWriteOff? writeOff;
    if (json['writeOff'] != null) {
      final writeOffJson = json['writeOff'] as Map<String, dynamic>;
      writeOff = AssetWriteOff(
        id: writeOffJson['id'] as String,
        assetId: json['id'] as String,
        writeOffDate: DateTime.parse(writeOffJson['writeOffDate'] as String),
        reason: writeOffJson['reason'] as String,
        writeOffAmount: writeOffJson['writeOffAmount'] != null
            ? (writeOffJson['writeOffAmount'] as num).toDouble()
            : null,
        documentUrl: writeOffJson['documentUrl'] as String?,
      );
    }

    // Парсинг передач
    List<AssetTransfer>? transfers;
    if (json['transfers'] != null) {
      final transfersList = json['transfers'] as List<dynamic>;
      transfers = transfersList.map((transferJson) {
        final tJson = transferJson as Map<String, dynamic>;
        return AssetTransfer(
          id: tJson['id'] as String,
          assetId: json['id'] as String,
          fromUserId: tJson['fromUserId'] as String?,
          toUserId: tJson['toUserId'] as String,
          transferDate: DateTime.parse(tJson['transferDate'] as String),
          reason: tJson['reason'] as String?,
          comment: tJson['comment'] as String?,
          createdBy: tJson['createdBy'] as String,
          fromUser: tJson['fromUser'] != null
              ? ProfileUser(
                  id: (tJson['fromUser'] as Map<String, dynamic>)['id'] as String,
                  email: (tJson['fromUser'] as Map<String, dynamic>)['email'] as String? ?? '',
                  firstName: (tJson['fromUser'] as Map<String, dynamic>)['firstName'] as String?,
                  lastName: (tJson['fromUser'] as Map<String, dynamic>)['lastName'] as String?,
                  patronymic: (tJson['fromUser'] as Map<String, dynamic>)['patronymic'] as String?,
                  phone: (tJson['fromUser'] as Map<String, dynamic>)['phone'] as String?,
                )
              : null,
          toUser: ProfileUser(
            id: (tJson['toUser'] as Map<String, dynamic>)['id'] as String,
            email: (tJson['toUser'] as Map<String, dynamic>)['email'] as String? ?? '',
            firstName: (tJson['toUser'] as Map<String, dynamic>)['firstName'] as String?,
            lastName: (tJson['toUser'] as Map<String, dynamic>)['lastName'] as String?,
            patronymic: (tJson['toUser'] as Map<String, dynamic>)['patronymic'] as String?,
            phone: (tJson['toUser'] as Map<String, dynamic>)['phone'] as String?,
          ),
        );
      }).toList();
    }

    // Парсинг ремонтов
    List<AssetRepair>? repairs;
    if (json['repairs'] != null) {
      final repairsList = json['repairs'] as List<dynamic>;
      repairs = repairsList.map((repairJson) {
        final rJson = repairJson as Map<String, dynamic>;
        return AssetRepair(
          id: rJson['id'] as String,
          assetId: json['id'] as String,
          repairDate: DateTime.parse(rJson['repairDate'] as String),
          repairType: rJson['repairType'] as String,
          cost: (rJson['cost'] as num).toDouble(),
          description: rJson['description'] as String?,
          createdBy: rJson['createdBy'] as String,
        );
      }).toList();
    }

    // Парсинг фото
    List<AssetPhoto>? photos;
    if (json['photos'] != null) {
      final photosList = json['photos'] as List<dynamic>;
      photos = photosList.map((photoJson) {
        final pJson = photoJson as Map<String, dynamic>;
        return AssetPhoto(
          id: pJson['id'] as String,
          assetId: json['id'] as String,
          fileUrl: pJson['fileUrl'] as String,
          fileName: pJson['fileName'] as String?,
          fileType: pJson['fileType'] as String?,
          isInventoryPhoto: pJson['isInventoryPhoto'] as bool? ?? false,
          inventoryId: pJson['inventoryId'] as String?,
        );
      }).toList();
    }

    // Парсинг инвентаризаций
    List<AssetInventory>? inventories;
    if (json['inventories'] != null) {
      final inventoriesList = json['inventories'] as List<dynamic>;
      inventories = inventoriesList.map((inventoryJson) {
        final iJson = inventoryJson as Map<String, dynamic>;
        return AssetInventory(
          id: iJson['id'] as String,
          assetId: json['id'] as String,
          inventoryDate: DateTime.parse(iJson['inventoryDate'] as String),
          status: iJson['status'] as String?,
          comment: iJson['comment'] as String?,
          conductedBy: iJson['conductedBy'] as String,
        );
      }).toList();
    }

    // Парсинг статистики из _count
    int? repairsCount;
    int? photosCount;
    int? tasksCount;
    if (json['_count'] != null) {
      final countJson = json['_count'] as Map<String, dynamic>;
      repairsCount = countJson['repairs'] as int?;
      photosCount = countJson['photos'] as int?;
      tasksCount = countJson['tasks'] as int?;
    }

    return FixedAssetModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      projectId: json['projectId'] as String?,
      name: json['name'] as String,
      model: json['model'] as String?,
      type: _parseAssetType(json['type'] as String),
      inventoryNumber: json['inventoryNumber'] as String?,
      serialNumber: json['serialNumber'] as String?,
      locationCity: json['locationCity'] as String?,
      locationAddress: json['locationAddress'] as String?,
      condition: _parseAssetCondition(json['condition'] as String),
      departmentId: json['departmentId'] as String?,
      currentOwnerId: json['currentOwnerId'] as String,
      creationDate: DateTime.parse(json['creationDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'] as String)
          : null,
      currentOwner: currentOwner,
      department: department,
      project: project,
      repairsCount: repairsCount ?? json['repairsCount'] as int?,
      photosCount: photosCount ?? json['photosCount'] as int?,
      tasksCount: tasksCount ?? json['tasksCount'] as int?,
      writeOff: writeOff,
      transfers: transfers,
      repairs: repairs,
      photos: photos,
      inventories: inventories,
      repairsTotal: json['repairsTotal'] != null
          ? (json['repairsTotal'] as num).toDouble()
          : null,
    );
  }

  static AssetType _parseAssetType(String type) {
    switch (type.toUpperCase()) {
      case 'EQUIPMENT':
        return AssetType.equipment;
      case 'FURNITURE':
        return AssetType.furniture;
      case 'OFFICE_TECH':
        return AssetType.officeTech;
      case 'OTHER':
        return AssetType.other;
      default:
        return AssetType.other;
    }
  }

  static AssetCondition _parseAssetCondition(String condition) {
    switch (condition.toUpperCase()) {
      case 'NEW_UP_TO_3_MONTHS':
        return AssetCondition.newUpTo3Months;
      case 'GOOD':
        return AssetCondition.good;
      case 'SATISFACTORY':
        return AssetCondition.satisfactory;
      case 'NOT_WORKING':
        return AssetCondition.notWorking;
      case 'WRITTEN_OFF':
        return AssetCondition.writtenOff;
      default:
        return AssetCondition.good;
    }
  }

  static String _assetTypeToString(AssetType type) {
    switch (type) {
      case AssetType.equipment:
        return 'EQUIPMENT';
      case AssetType.furniture:
        return 'FURNITURE';
      case AssetType.officeTech:
        return 'OFFICE_TECH';
      case AssetType.other:
        return 'OTHER';
    }
  }

  static String _assetConditionToString(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return 'NEW_UP_TO_3_MONTHS';
      case AssetCondition.good:
        return 'GOOD';
      case AssetCondition.satisfactory:
        return 'SATISFACTORY';
      case AssetCondition.notWorking:
        return 'NOT_WORKING';
      case AssetCondition.writtenOff:
        return 'WRITTEN_OFF';
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      if (projectId != null) 'projectId': projectId,
      'name': name,
      if (model != null) 'model': model,
      'type': _assetTypeToString(type),
      if (inventoryNumber != null) 'inventoryNumber': inventoryNumber,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (locationCity != null) 'locationCity': locationCity,
      if (locationAddress != null) 'locationAddress': locationAddress,
      'condition': _assetConditionToString(condition),
      if (departmentId != null) 'departmentId': departmentId,
      'currentOwnerId': currentOwnerId,
      'creationDate': creationDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (archivedAt != null) 'archivedAt': archivedAt!.toIso8601String(),
    };
  }

  /// Преобразование в JSON для создания актива
  Map<String, dynamic> toCreateJson() {
    return {
      'businessId': businessId,
      'name': name,
      'type': _assetTypeToString(type),
      'condition': _assetConditionToString(condition),
      if (projectId != null) 'projectId': projectId,
      if (model != null && model!.isNotEmpty) 'model': model,
      if (inventoryNumber != null && inventoryNumber!.isNotEmpty)
        'inventoryNumber': inventoryNumber,
      if (serialNumber != null && serialNumber!.isNotEmpty)
        'serialNumber': serialNumber,
      if (locationCity != null && locationCity!.isNotEmpty)
        'locationCity': locationCity,
      if (locationAddress != null && locationAddress!.isNotEmpty)
        'locationAddress': locationAddress,
      if (departmentId != null) 'departmentId': departmentId,
      if (creationDate != createdAt) 'creationDate': creationDate.toIso8601String(),
    };
  }

  /// Преобразование в JSON для обновления актива
  Map<String, dynamic> toUpdateJson() {
    return {
      if (name.isNotEmpty) 'name': name,
      if (model != null) 'model': model,
      'type': _assetTypeToString(type),
      if (inventoryNumber != null) 'inventoryNumber': inventoryNumber,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (locationCity != null) 'locationCity': locationCity,
      if (locationAddress != null) 'locationAddress': locationAddress,
      'condition': _assetConditionToString(condition),
      if (projectId != null) 'projectId': projectId,
      if (departmentId != null) 'departmentId': departmentId,
      if (creationDate != createdAt) 'creationDate': creationDate.toIso8601String(),
    };
  }

  FixedAsset toEntity() {
    return FixedAsset(
      id: id,
      businessId: businessId,
      projectId: projectId,
      name: name,
      model: model,
      type: type,
      inventoryNumber: inventoryNumber,
      serialNumber: serialNumber,
      locationCity: locationCity,
      locationAddress: locationAddress,
      condition: condition,
      departmentId: departmentId,
      currentOwnerId: currentOwnerId,
      creationDate: creationDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
      currentOwner: currentOwner,
      department: department,
      project: project,
      repairsCount: repairsCount,
      photosCount: photosCount,
      tasksCount: tasksCount,
      writeOff: writeOff,
      transfers: transfers,
      repairs: repairs,
      photos: photos,
      inventories: inventories,
      repairsTotal: repairsTotal,
    );
  }

  factory FixedAssetModel.fromEntity(FixedAsset asset) {
    return FixedAssetModel(
      id: asset.id,
      businessId: asset.businessId,
      projectId: asset.projectId,
      name: asset.name,
      model: asset.model,
      type: asset.type,
      inventoryNumber: asset.inventoryNumber,
      serialNumber: asset.serialNumber,
      locationCity: asset.locationCity,
      locationAddress: asset.locationAddress,
      condition: asset.condition,
      departmentId: asset.departmentId,
      currentOwnerId: asset.currentOwnerId,
      creationDate: asset.creationDate,
      createdAt: asset.createdAt,
      updatedAt: asset.updatedAt,
      archivedAt: asset.archivedAt,
      currentOwner: asset.currentOwner,
      department: asset.department,
      project: asset.project,
      repairsCount: asset.repairsCount,
      photosCount: asset.photosCount,
      tasksCount: asset.tasksCount,
      writeOff: asset.writeOff,
      transfers: asset.transfers,
      repairs: asset.repairs,
      photos: asset.photos,
      inventories: asset.inventories,
      repairsTotal: asset.repairsTotal,
    );
  }
}
