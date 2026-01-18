import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/usecases/get_fixed_asset_by_id.dart';
import '../../domain/usecases/update_fixed_asset.dart';
import '../../domain/usecases/transfer_fixed_asset.dart';
import '../../domain/usecases/add_repair.dart';
import '../../domain/usecases/add_inventory.dart';
import '../../domain/usecases/add_photo.dart';
import '../../domain/usecases/write_off_fixed_asset.dart';
import '../../domain/usecases/archive_fixed_asset.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../providers/project_provider.dart';
import '../providers/department_provider.dart';
import '../widgets/user_selector_widget.dart';
import '../widgets/create_fixed_asset_form.dart';

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Действия',
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _showEditDialog();
                  break;
                case 'transfer':
                  _showTransferDialog();
                  break;
                case 'repair':
                  _showAddRepairDialog();
                  break;
                case 'inventory':
                  _showAddInventoryDialog();
                  break;
                case 'photo':
                  _showAddPhotoDialog();
                  break;
                case 'writeoff':
                  _showWriteOffDialog();
                  break;
                case 'archive':
                  _showArchiveConfirm();
                  break;
              }
            },
            itemBuilder: (context) {
              final isArchived = _asset?.archivedAt != null;
              final isWrittenOff = _asset?.writeOff != null;
              return [
                if (!isArchived)
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'transfer',
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Передать'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'repair',
                  child: ListTile(
                    leading: Icon(Icons.build),
                    title: Text('Добавить ремонт'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'inventory',
                  child: ListTile(
                    leading: Icon(Icons.checklist),
                    title: Text('Добавить инвентаризацию'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'photo',
                  child: ListTile(
                    leading: Icon(Icons.photo_camera),
                    title: Text('Добавить фото'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (!isWrittenOff)
                  const PopupMenuItem(
                    value: 'writeoff',
                    child: ListTile(
                      leading: Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('Списать', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (!isArchived)
                  const PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(Icons.archive),
                      title: Text('Архивировать'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ];
            },
          ),
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

  void _showEditDialog() {
    if (_asset == null) return;
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    final departmentProvider = Provider.of<DepartmentProvider>(context, listen: false);
    projectProvider.loadProjects(_asset!.businessId);
    departmentProvider.loadDepartments(_asset!.businessId);
    showDialog(
      context: context,
      builder: (ctx) => _EditFixedAssetDialog(
        asset: _asset!,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showTransferDialog() {
    if (_asset == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _TransferAssetDialog(
        assetId: widget.assetId,
        businessId: _asset!.businessId,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showAddRepairDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddRepairDialog(
        assetId: widget.assetId,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showAddInventoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddInventoryDialog(
        assetId: widget.assetId,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showAddPhotoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddPhotoDialog(
        assetId: widget.assetId,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showWriteOffDialog() {
    if (_asset == null) return;
    showDialog(
      context: context,
      builder: (ctx) => _WriteOffAssetDialog(
        assetId: widget.assetId,
        onSuccess: () {
          Navigator.of(ctx).pop();
          _loadAsset();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _showArchiveConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Архивировать актив?'),
        content: const Text(
          'После архивации он будет скрыт из основного списка. '
          'Вы сможете просматривать архивные активы, включив фильтр «Включать архивные».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final archiveUseCase = Provider.of<ArchiveFixedAsset>(context, listen: false);
              final result = await archiveUseCase.call(widget.assetId);
              if (!mounted) return;
              result.fold(
                (f) => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(f.message), backgroundColor: Colors.red),
                ),
                (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Актив архивирован'), backgroundColor: Colors.green),
                  );
                  Navigator.of(context).pop(); // возврат к списку
                },
              );
            },
            child: const Text('Архивировать'),
          ),
        ],
      ),
    );
  }
}

// --- Диалоги действий ---

class _EditFixedAssetDialog extends StatefulWidget {
  final FixedAsset asset;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _EditFixedAssetDialog({
    required this.asset,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<_EditFixedAssetDialog> createState() => _EditFixedAssetDialogState();
}

class _EditFixedAssetDialogState extends State<_EditFixedAssetDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  const Text('Редактировать основное средство', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: widget.onCancel),
                ],
              ),
            ),
            Expanded(
              child: CreateFixedAssetForm(
                businessId: widget.asset.businessId,
                userRepository: Provider.of<UserRepository>(context, listen: false),
                initialAsset: widget.asset,
                error: _error,
                validationErrors: _validationErrors,
                onError: (e) => setState(() => _error = e),
                onSubmit: (asset) async {
                  final u = Provider.of<UpdateFixedAsset>(context, listen: false);
                  final r = await u.call(UpdateFixedAssetParams(id: asset.id, asset: asset));
                  if (!mounted) return;
                  r.fold(
                    (f) => setState(() {
                      _error = f is ValidationFailure ? (f.serverMessage ?? f.message) : f.message;
                      _validationErrors = f is ValidationFailure ? f.errors : null;
                    }),
                    (_) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Изменения сохранены'), backgroundColor: Colors.green));
                      widget.onSuccess();
                    },
                  );
                },
                onCancel: widget.onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferAssetDialog extends StatefulWidget {
  final String assetId;
  final String businessId;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _TransferAssetDialog({required this.assetId, required this.businessId, required this.onSuccess, required this.onCancel});

  @override
  State<_TransferAssetDialog> createState() => _TransferAssetDialogState();
}

class _TransferAssetDialogState extends State<_TransferAssetDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _toUserId;
  DateTime _transferDate = DateTime.now();
  String? _reason;
  String? _comment;
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Передать актив', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                UserSelectorWidget(
                  businessId: widget.businessId,
                  userRepository: Provider.of<UserRepository>(context, listen: false),
                  selectedUserId: _toUserId,
                  onUserSelected: (v) => setState(() => _toUserId = v),
                  label: 'Новый владелец *',
                  required: true,
                ),
                const SizedBox(height: 12),
                FormBuilderDateTimePicker(
                  name: 'transferDate',
                  initialValue: _transferDate,
                  onChanged: (v) => setState(() => _transferDate = v ?? DateTime.now()),
                  decoration: const InputDecoration(labelText: 'Дата передачи', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  inputType: InputType.date,
                ),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'reason', initialValue: _reason, decoration: const InputDecoration(labelText: 'Причина', border: OutlineInputBorder()), onChanged: (v) => _reason = v),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'comment', initialValue: _comment, decoration: const InputDecoration(labelText: 'Комментарий', border: OutlineInputBorder()), onChanged: (v) => _comment = v),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Отмена')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _loading ? null : () async {
                        if (_toUserId == null || _toUserId!.isEmpty) { setState(() => _error = 'Выберите нового владельца'); return; }
                        setState(() { _error = null; _loading = true; });
                        _formKey.currentState?.save();
                        final form = _formKey.currentState;
                        if (form != null) { _transferDate = form.value['transferDate'] as DateTime? ?? _transferDate; _reason = form.value['reason'] as String?; _comment = form.value['comment'] as String?; }
                        final u = Provider.of<TransferFixedAsset>(context, listen: false);
                        final r = await u.call(TransferFixedAssetParams(id: widget.assetId, toUserId: _toUserId!, transferDate: _transferDate, reason: _reason, comment: _comment));
                        if (!mounted) return;
                        setState(() => _loading = false);
                        r.fold((f) => setState(() => _error = f.message), (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Актив передан'), backgroundColor: Colors.green)); widget.onSuccess(); });
                      },
                      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Передать'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddRepairDialog extends StatefulWidget {
  final String assetId;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _AddRepairDialog({required this.assetId, required this.onSuccess, required this.onCancel});

  @override
  State<_AddRepairDialog> createState() => _AddRepairDialogState();
}

class _AddRepairDialogState extends State<_AddRepairDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Добавить ремонт', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                FormBuilderDateTimePicker(name: 'repairDate', initialValue: DateTime.now(), decoration: const InputDecoration(labelText: 'Дата *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), inputType: InputType.date, validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'repairType', decoration: const InputDecoration(labelText: 'Тип ремонта *', border: OutlineInputBorder()), validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'cost', decoration: const InputDecoration(labelText: 'Стоимость (₸) *', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: FormBuilderValidators.compose([FormBuilderValidators.required(errorText: 'Обязательно'), FormBuilderValidators.numeric(errorText: 'Число')])),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'description', decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
                      final v = _formKey.currentState!.value;
                      setState(() { _error = null; _loading = true; });
                      final u = Provider.of<AddRepair>(context, listen: false);
                      final cost = double.tryParse((v['cost'] ?? '').toString()) ?? 0.0;
                      final r = await u.call(AddRepairParams(id: widget.assetId, repairDate: v['repairDate'] as DateTime? ?? DateTime.now(), repairType: v['repairType'] as String? ?? '', cost: cost, description: v['description'] as String?));
                      if (!mounted) return;
                      setState(() => _loading = false);
                      r.fold((f) => setState(() => _error = f.message), (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ремонт добавлен'), backgroundColor: Colors.green)); widget.onSuccess(); });
                    },
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Добавить'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddInventoryDialog extends StatefulWidget {
  final String assetId;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _AddInventoryDialog({required this.assetId, required this.onSuccess, required this.onCancel});

  @override
  State<_AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<_AddInventoryDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Добавить инвентаризацию', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                FormBuilderDateTimePicker(name: 'inventoryDate', initialValue: DateTime.now(), decoration: const InputDecoration(labelText: 'Дата *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), inputType: InputType.date, validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'status', decoration: const InputDecoration(labelText: 'Статус', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'comment', decoration: const InputDecoration(labelText: 'Комментарий', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
                      final v = _formKey.currentState!.value;
                      setState(() { _error = null; _loading = true; });
                      final u = Provider.of<AddInventory>(context, listen: false);
                      final r = await u.call(AddInventoryParams(id: widget.assetId, inventoryDate: v['inventoryDate'] as DateTime? ?? DateTime.now(), status: v['status'] as String?, comment: v['comment'] as String?));
                      if (!mounted) return;
                      setState(() => _loading = false);
                      r.fold((f) => setState(() => _error = f.message), (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Инвентаризация добавлена'), backgroundColor: Colors.green)); widget.onSuccess(); });
                    },
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Добавить'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoDialog extends StatefulWidget {
  final String assetId;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _AddPhotoDialog({required this.assetId, required this.onSuccess, required this.onCancel});

  @override
  State<_AddPhotoDialog> createState() => _AddPhotoDialogState();
}

class _AddPhotoDialogState extends State<_AddPhotoDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Добавить фото', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Вставьте URL изображения (файл должен быть загружен отдельно).', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                FormBuilderTextField(name: 'fileUrl', decoration: const InputDecoration(labelText: 'URL файла *', border: OutlineInputBorder()), validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'fileName', decoration: const InputDecoration(labelText: 'Имя файла', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                FormBuilderCheckbox(name: 'isInventoryPhoto', initialValue: false, title: const Text('Инвентарное фото')),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _loading ? null : () async {
                      if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
                      final v = _formKey.currentState!.value;
                      setState(() { _error = null; _loading = true; });
                      final u = Provider.of<AddPhoto>(context, listen: false);
                      final r = await u.call(AddPhotoParams(id: widget.assetId, fileUrl: v['fileUrl'] as String? ?? '', fileName: v['fileName'] as String?, isInventoryPhoto: v['isInventoryPhoto'] as bool?));
                      if (!mounted) return;
                      setState(() => _loading = false);
                      r.fold((f) => setState(() => _error = f.message), (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото добавлено'), backgroundColor: Colors.green)); widget.onSuccess(); });
                    },
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Добавить'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WriteOffAssetDialog extends StatefulWidget {
  final String assetId;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const _WriteOffAssetDialog({required this.assetId, required this.onSuccess, required this.onCancel});

  @override
  State<_WriteOffAssetDialog> createState() => _WriteOffAssetDialogState();
}

class _WriteOffAssetDialogState extends State<_WriteOffAssetDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  String? _error;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(16),
        child: FormBuilder(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Списать актив', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                FormBuilderDateTimePicker(name: 'writeOffDate', initialValue: DateTime.now(), decoration: const InputDecoration(labelText: 'Дата списания *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), inputType: InputType.date, validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'reason', decoration: const InputDecoration(labelText: 'Причина *', border: OutlineInputBorder()), validator: FormBuilderValidators.required(errorText: 'Обязательно')),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'writeOffAmount', decoration: const InputDecoration(labelText: 'Сумма списания (₸)', border: OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                FormBuilderTextField(name: 'documentUrl', decoration: const InputDecoration(labelText: 'URL документа', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: _loading ? null : widget.onCancel, child: const Text('Отмена')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _loading ? null : () async {
                      if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
                      final v = _formKey.currentState!.value;
                      setState(() { _error = null; _loading = true; });
                      final u = Provider.of<WriteOffFixedAsset>(context, listen: false);
                      final amount = double.tryParse((v['writeOffAmount'] ?? '').toString());
                      final r = await u.call(WriteOffFixedAssetParams(id: widget.assetId, writeOffDate: v['writeOffDate'] as DateTime? ?? DateTime.now(), reason: v['reason'] as String? ?? '', writeOffAmount: amount, documentUrl: v['documentUrl'] as String?));
                      if (!mounted) return;
                      setState(() => _loading = false);
                      r.fold((f) => setState(() => _error = f.message), (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Актив списан'), backgroundColor: Colors.green)); widget.onSuccess(); });
                    },
                    child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Списать'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
