import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/usecases/get_fixed_assets.dart';
import '../providers/profile_provider.dart';

/// Страница основных средств
class FixedAssetsPage extends StatefulWidget {
  const FixedAssetsPage({super.key});

  @override
  State<FixedAssetsPage> createState() => _FixedAssetsPageState();
}

class _FixedAssetsPageState extends State<FixedAssetsPage> {
  List<FixedAsset> _assets = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAssets();
    });
  }

  Future<void> _loadAssets() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _error = 'Компания не выбрана';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getFixedAssetsUseCase = Provider.of<GetFixedAssets>(context, listen: false);
    final result = await getFixedAssetsUseCase.call(
      GetFixedAssetsParams(
        businessId: selectedBusiness.id,
        limit: 50,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message.isNotEmpty
              ? failure.message
              : 'Ошибка при загрузке основных средств';
          _isLoading = false;
        });
      },
      (assets) {
        setState(() {
          _assets = assets;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Основные средства'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Выберите компанию')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Основные средства'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssets,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_assets.isEmpty) {
      return const Center(child: Text('Нет основных средств'));
    }

    return ListView.builder(
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return ListTile(
          title: Text(asset.name),
          subtitle: Text(
            'Тип: ${_getAssetTypeName(asset.type)}\n'
            'Состояние: ${_getAssetConditionName(asset.condition)}\n'
            'Владелец: ${asset.currentOwner?.firstName ?? asset.currentOwnerId}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: Навигация на детальную страницу актива
            // Пока просто показываем snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Актив: ${asset.name} (ID: ${asset.id})'),
              ),
            );
          },
        );
      },
    );
  }

  String _getAssetTypeName(AssetType type) {
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

  String _getAssetConditionName(AssetCondition condition) {
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
}
