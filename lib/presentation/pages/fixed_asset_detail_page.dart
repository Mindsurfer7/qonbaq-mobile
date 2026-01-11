import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/usecases/get_fixed_asset_by_id.dart';
import '../../core/error/failures.dart';

/// Детальная страница основного средства
class FixedAssetDetailPage extends StatefulWidget {
  final String assetId;

  const FixedAssetDetailPage({
    super.key,
    required this.assetId,
  });

  @override
  State<FixedAssetDetailPage> createState() => _FixedAssetDetailPageState();
}

class _FixedAssetDetailPageState extends State<FixedAssetDetailPage> {
  FixedAsset? _asset;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getAssetUseCase = Provider.of<GetFixedAssetById>(context, listen: false);
    final result = await getAssetUseCase.call(widget.assetId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке основного средства'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (asset) {
        setState(() {
          _isLoading = false;
          _asset = asset;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }

  String _formatDateTimeWithTime(DateTime dateTime) {
    return '${_formatDateTime(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _getAssetTypeText(AssetType type) {
    switch (type) {
      case AssetType.equipment:
        return 'Оборудование';
      case AssetType.furniture:
        return 'Мебель';
      case AssetType.officeTech:
        return 'Орг.техника';
      case AssetType.other:
        return 'Прочее';
    }
  }

  String _getConditionText(AssetCondition condition) {
    switch (condition) {
      case AssetCondition.newUpTo3Months:
        return 'Новое (до 3-х месяцев)';
      case AssetCondition.good:
        return 'Хорошее';
      case AssetCondition.satisfactory:
        return 'Удовлетворительное';
      case AssetCondition.notWorking:
        return 'Не рабочее';
      case AssetCondition.writtenOff:
        return 'Списано по акту';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_asset?.name ?? 'Основное средство'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAsset,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAsset,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _asset == null
                  ? const Center(child: Text('Основное средство не найдено'))
                  : _buildDetailView(),
    );
  }

  Widget _buildDetailView() {
    return RefreshIndicator(
      onRefresh: _loadAsset,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и состояние
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getAssetTypeColor(_asset!.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAssetTypeIcon(_asset!.type),
                    color: _getAssetTypeColor(_asset!.type),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _asset!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_asset!.model != null && _asset!.model!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _asset!.model!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getConditionColor(_asset!.condition),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getConditionText(_asset!.condition),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Основная информация
            const Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoRow('Тип', _getAssetTypeText(_asset!.type),
                Icons.category),
            _buildInfoRow('Состояние', _getConditionText(_asset!.condition),
                Icons.check_circle),
            if (_asset!.inventoryNumber != null &&
                _asset!.inventoryNumber!.isNotEmpty)
              _buildInfoRow('Инвентарный номер', _asset!.inventoryNumber!,
                  Icons.confirmation_number),
            if (_asset!.serialNumber != null &&
                _asset!.serialNumber!.isNotEmpty)
              _buildInfoRow('Серийный номер', _asset!.serialNumber!,
                  Icons.numbers),
            _buildInfoRow('Дата создания', _formatDateTime(_asset!.creationDate),
                Icons.calendar_today),
            _buildInfoRow('Дата добавления', _formatDateTimeWithTime(_asset!.createdAt),
                Icons.add_circle),
            _buildInfoRow('Дата обновления', _formatDateTimeWithTime(_asset!.updatedAt),
                Icons.update),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Местоположение
            if (_asset!.locationCity != null ||
                _asset!.locationAddress != null ||
                _asset!.department != null ||
                _asset!.project != null) ...[
              const Text(
                'Местоположение',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_asset!.locationCity != null &&
                  _asset!.locationCity!.isNotEmpty)
                _buildInfoRow('Город', _asset!.locationCity!, Icons.location_city),
              if (_asset!.locationAddress != null &&
                  _asset!.locationAddress!.isNotEmpty)
                _buildInfoRow('Адрес', _asset!.locationAddress!, Icons.location_on),
              if (_asset!.department != null)
                _buildInfoRow('Подразделение', _asset!.department!.name,
                    Icons.business),
              if (_asset!.project != null)
                _buildInfoRow('Проект', _asset!.project!.name, Icons.folder),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Владелец
            const Text(
              'Ответственное лицо',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_asset!.currentOwner != null)
              _buildInfoRow('Владелец', _getUserDisplayName(_asset!.currentOwner!),
                  Icons.person),
            if (_asset!.currentOwner == null)
              _buildInfoRow('Владелец', _asset!.currentOwnerId, Icons.person),

            // Статистика
            if (_hasStatistics()) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Статистика',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_asset!.repairsCount != null && _asset!.repairsCount! > 0)
                _buildInfoRow('Количество ремонтов', '${_asset!.repairsCount}',
                    Icons.build),
              if (_asset!.repairsTotal != null && _asset!.repairsTotal! > 0)
                _buildInfoRow('Сумма ремонтов', '${_asset!.repairsTotal!.toStringAsFixed(2)} ₸',
                    Icons.attach_money),
              if (_asset!.photosCount != null && _asset!.photosCount! > 0)
                _buildInfoRow('Количество фото', '${_asset!.photosCount}',
                    Icons.photo),
              if (_asset!.tasksCount != null && _asset!.tasksCount! > 0)
                _buildInfoRow('Количество задач', '${_asset!.tasksCount}',
                    Icons.assignment),
            ],

            // Списание
            if (_asset!.writeOff != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Информация о списании',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Дата списания',
                  _formatDateTime(_asset!.writeOff!.writeOffDate),
                  Icons.delete_forever,
                  color: Colors.red),
              _buildInfoRow('Причина списания', _asset!.writeOff!.reason,
                  Icons.description,
                  color: Colors.red),
              if (_asset!.writeOff!.writeOffAmount != null)
                _buildInfoRow('Сумма списания',
                    '${_asset!.writeOff!.writeOffAmount!.toStringAsFixed(2)} ₸',
                    Icons.attach_money,
                    color: Colors.red),
            ],

            // История передач
            if (_asset!.transfers != null && _asset!.transfers!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'История передач',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_asset!.transfers!.map((transfer) =>
                  _buildTransferCard(transfer))),
            ],

            // История ремонтов
            if (_asset!.repairs != null && _asset!.repairs!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'История ремонтов',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_asset!.repairs!.map((repair) => _buildRepairCard(repair))),
            ],

            // Фото
            if (_asset!.photos != null && _asset!.photos!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Фото',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _asset!.photos!
                    .map((photo) => _buildPhotoThumbnail(photo))
                    .toList(),
              ),
            ],

            // Инвентаризации
            if (_asset!.inventories != null && _asset!.inventories!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Инвентаризации',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...(_asset!.inventories!
                  .map((inventory) => _buildInventoryCard(inventory))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferCard(AssetTransfer transfer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(transfer.transferDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (transfer.fromUser != null)
              Text('От: ${_getUserDisplayName(transfer.fromUser!)}'),
            Text('К: ${_getUserDisplayName(transfer.toUser)}'),
            if (transfer.reason != null && transfer.reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Причина: ${transfer.reason}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (transfer.comment != null && transfer.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                transfer.comment!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRepairCard(AssetRepair repair) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDateTime(repair.repairDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${repair.cost.toStringAsFixed(2)} ₸',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Тип ремонта: ${repair.repairType}'),
            if (repair.description != null && repair.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                repair.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(AssetPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        photo.fileUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      ),
    );
  }

  Widget _buildInventoryCard(AssetInventory inventory) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, size: 20, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(inventory.inventoryDate),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (inventory.status != null && inventory.status!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Статус: ${inventory.status}'),
            ],
            if (inventory.comment != null && inventory.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                inventory.comment!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasStatistics() {
    return (_asset!.repairsCount != null && _asset!.repairsCount! > 0) ||
        (_asset!.repairsTotal != null && _asset!.repairsTotal! > 0) ||
        (_asset!.photosCount != null && _asset!.photosCount! > 0) ||
        (_asset!.tasksCount != null && _asset!.tasksCount! > 0);
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
}
