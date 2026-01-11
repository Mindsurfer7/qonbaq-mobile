import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/fixed_asset.dart';
import '../../domain/usecases/get_fixed_assets.dart';
import '../../domain/usecases/create_fixed_asset.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../providers/profile_provider.dart';
import '../widgets/create_fixed_asset_form.dart';
import '../widgets/fixed_asset_card.dart';
import '../../core/theme/theme_extensions.dart';

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

  void _showCreateAssetDialog() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createFixedAssetUseCase = Provider.of<CreateFixedAsset>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) return;

    showDialog(
      context: context,
      builder: (context) => _CreateFixedAssetDialog(
        businessId: selectedBusiness.id,
        userRepository: userRepository,
        createFixedAssetUseCase: createFixedAssetUseCase,
        onSuccess: () {
          _loadAssets();
        },
      ),
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
      floatingActionButton: FloatingActionButton(
        heroTag: "create_fixed_asset",
        onPressed: _showCreateAssetDialog,
        backgroundColor: context.appTheme.accentPrimary,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        return FixedAssetCard(
          asset: asset,
          onTap: () {
            Navigator.of(context).pushNamed(
              '/business/admin/fixed_assets/detail',
              arguments: asset.id,
            );
          },
        );
      },
    );
  }

}

/// Диалог создания основного средства
class _CreateFixedAssetDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateFixedAsset createFixedAssetUseCase;
  final VoidCallback onSuccess;

  const _CreateFixedAssetDialog({
    required this.businessId,
    required this.userRepository,
    required this.createFixedAssetUseCase,
    required this.onSuccess,
  });

  @override
  State<_CreateFixedAssetDialog> createState() => _CreateFixedAssetDialogState();
}

class _CreateFixedAssetDialogState extends State<_CreateFixedAssetDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Создать основное средство',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Форма
            Expanded(
              child: CreateFixedAssetForm(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                error: _error,
                validationErrors: _validationErrors,
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                },
                onSubmit: (asset) async {
                  final result = await widget.createFixedAssetUseCase.call(
                    CreateFixedAssetParams(asset: asset),
                  );

                  result.fold(
                    (failure) {
                      // Обрабатываем ошибки валидации
                      if (failure is ValidationFailure) {
                        setState(() {
                          _error = failure.serverMessage ?? failure.message;
                          _validationErrors = failure.errors;
                        });
                      } else {
                        setState(() {
                          _error = _getErrorMessage(failure);
                          _validationErrors = null;
                        });
                      }
                    },
                    (createdAsset) {
                      // Закрываем диалог и показываем успех
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Основное средство успешно создано'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        widget.onSuccess();
                      }
                    },
                  );
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
