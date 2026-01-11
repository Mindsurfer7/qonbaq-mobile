import 'package:flutter/material.dart';
import '../../domain/entities/fixed_asset.dart';

/// Мини-карточка основного средства для отображения в списке
class FixedAssetCard extends StatelessWidget {
  final FixedAsset asset;
  final VoidCallback? onTap;

  const FixedAssetCard({
    super.key,
    required this.asset,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Иконка типа актива
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAssetTypeColor(asset.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getAssetTypeIcon(asset.type),
                      color: _getAssetTypeColor(asset.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Название и модель
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (asset.model != null && asset.model!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            asset.model!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Статус состояния
                  _buildConditionChip(context),
                ],
              ),
              const SizedBox(height: 12),
              // Дополнительная информация
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (asset.inventoryNumber != null && asset.inventoryNumber!.isNotEmpty)
                    _buildInfoRow(
                      context,
                      Icons.confirmation_number,
                      'Инв. №: ${asset.inventoryNumber}',
                    ),
                  if (asset.currentOwner != null)
                    _buildInfoRow(
                      context,
                      Icons.person,
                      _getUserDisplayName(asset.currentOwner!),
                    ),
                  if (asset.department != null)
                    _buildInfoRow(
                      context,
                      Icons.business,
                      asset.department!.name,
                    ),
                  if (asset.locationCity != null || asset.locationAddress != null)
                    _buildInfoRow(
                      context,
                      Icons.location_on,
                      _getLocationString(),
                    ),
                ],
              ),
              // Статистика (если есть)
              if (_hasStatistics())
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      if (asset.repairsCount != null && asset.repairsCount! > 0)
                        _buildStatChip(
                          context,
                          Icons.build,
                          '${asset.repairsCount} ремонт${_getPlural(asset.repairsCount!)}',
                        ),
                      if (asset.photosCount != null && asset.photosCount! > 0) ...[
                        if (asset.repairsCount != null && asset.repairsCount! > 0)
                          const SizedBox(width: 8),
                        _buildStatChip(
                          context,
                          Icons.photo,
                          '${asset.photosCount} фото',
                        ),
                      ],
                      if (asset.tasksCount != null && asset.tasksCount! > 0) ...[
                        if ((asset.repairsCount != null && asset.repairsCount! > 0) ||
                            (asset.photosCount != null && asset.photosCount! > 0))
                          const SizedBox(width: 8),
                        _buildStatChip(
                          context,
                          Icons.assignment,
                          '${asset.tasksCount} задач${_getPlural(asset.tasksCount!)}',
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConditionChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getConditionColor(asset.condition).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getConditionColor(asset.condition).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        _getConditionText(asset.condition),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _getConditionColor(asset.condition),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasStatistics() {
    return (asset.repairsCount != null && asset.repairsCount! > 0) ||
        (asset.photosCount != null && asset.photosCount! > 0) ||
        (asset.tasksCount != null && asset.tasksCount! > 0);
  }

  String _getLocationString() {
    final parts = <String>[];
    if (asset.locationCity != null && asset.locationCity!.isNotEmpty) {
      parts.add(asset.locationCity!);
    }
    if (asset.locationAddress != null && asset.locationAddress!.isNotEmpty) {
      parts.add(asset.locationAddress!);
    }
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String _getUserDisplayName(profileUser) {
    final parts = <String>[];
    if (profileUser.lastName != null && profileUser.lastName!.isNotEmpty) {
      parts.add(profileUser.lastName!);
    }
    if (profileUser.firstName != null && profileUser.firstName!.isNotEmpty) {
      parts.add(profileUser.firstName!);
    }
    if (profileUser.patronymic != null && profileUser.patronymic!.isNotEmpty) {
      parts.add(profileUser.patronymic!);
    }
    return parts.isEmpty ? profileUser.email ?? '' : parts.join(' ');
  }

  String _getPlural(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return '';
    } else if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'а';
    } else {
      return 'ов';
    }
  }

  IconData _getAssetTypeIcon(AssetType type) {
    switch (type) {
      case AssetType.equipment:
        return Icons.precision_manufacturing;
      case AssetType.furniture:
        return Icons.chair;
      case AssetType.officeTech:
        return Icons.computer;
      case AssetType.other:
        return Icons.inventory;
    }
  }

  Color _getAssetTypeColor(AssetType type) {
    switch (type) {
      case AssetType.equipment:
        return Colors.blue;
      case AssetType.furniture:
        return Colors.brown;
      case AssetType.officeTech:
        return Colors.purple;
      case AssetType.other:
        return Colors.grey;
    }
  }

  String _getConditionText(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return 'Новое';
      case AssetCondition.good:
        return 'Хорошее';
      case AssetCondition.satisfactory:
        return 'Удовлетв.';
      case AssetCondition.notWorking:
        return 'Не рабочее';
      case AssetCondition.writtenOff:
        return 'Списано';
    }
  }

  Color _getConditionColor(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return Colors.green;
      case AssetCondition.good:
        return Colors.blue;
      case AssetCondition.satisfactory:
        return Colors.orange;
      case AssetCondition.notWorking:
        return Colors.red;
      case AssetCondition.writtenOff:
        return Colors.grey;
    }
  }
}
