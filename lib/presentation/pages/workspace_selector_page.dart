import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/business.dart';
import '../widgets/create_business_dialog.dart';

/// Страница выбора workspace (семья или бизнес)
class WorkspaceSelectorPage extends StatefulWidget {
  const WorkspaceSelectorPage({super.key});

  @override
  State<WorkspaceSelectorPage> createState() => _WorkspaceSelectorPageState();
}

class _WorkspaceSelectorPageState extends State<WorkspaceSelectorPage> {
  @override
  void initState() {
    super.initState();
    // Загружаем список бизнесов при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      if (provider.businesses == null && !provider.isLoading) {
        provider.loadBusinesses();
      }
    });
  }

  Future<void> _selectWorkspace(Business workspace) async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.selectWorkspace(workspace);

    if (!mounted) return;

    // Переходим на главную страницу бизнеса
    Navigator.of(context).pushReplacementNamed('/business');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите пространство'),
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadBusinesses(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.businesses == null || provider.businesses!.isEmpty) {
            return const Center(child: Text('Нет доступных workspace'));
          }

          final familyBusiness = provider.familyBusiness;
          final businessList = provider.businessList;

          // Отладочная информация
          debugPrint('=== Workspace Selector Debug ===');
          debugPrint('Всего бизнесов: ${provider.businesses?.length ?? 0}');
          debugPrint('Семья: ${familyBusiness?.name ?? "нет"}');
          debugPrint('Бизнесов в списке: ${businessList.length}');
          if (provider.businesses != null) {
            for (var b in provider.businesses!) {
              debugPrint('  - ${b.name} (type: ${b.type})');
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Выберите пространство',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Левая часть - кнопка "Семья" (синяя)
                    Expanded(
                      child:
                          familyBusiness != null
                              ? _buildFamilyButton(familyBusiness)
                              : _buildAddFamilyButton(),
                    ),
                    if (businessList.isNotEmpty) const SizedBox(width: 12),
                    // Правая часть - список бизнесов (желтые) или кнопка создания
                    if (businessList.isNotEmpty)
                      Expanded(child: _buildBusinessList(businessList))
                    else
                      // Если нет бизнесов, показываем кнопку создания
                      Expanded(child: _buildAddBusinessButton()),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFamilyButton(Business familyBusiness) {
    return Card(
      color: Colors.blue,
      elevation: 2,
      child: InkWell(
        onTap: () => _selectWorkspace(familyBusiness),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.family_restroom, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Семья',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (familyBusiness.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    familyBusiness.name,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFamilyButton() {
    return Card(
      color: Colors.blue.shade100,
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await showDialog<Business>(
            context: context,
            builder:
                (context) =>
                    const CreateBusinessDialog(type: BusinessType.family),
          );

          if (result != null && mounted) {
            // Перезагружаем список бизнесов
            final provider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            await provider.loadBusinesses();
            // Автоматически выбираем созданный бизнес
            await _selectWorkspace(result);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 48,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              const Text(
                'Добавить семью',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessList(List<Business> businesses) {
    return Card(
      color: Colors.amber.shade50,
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Бизнесы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...businesses.map((business) {
              return Card(
                color: Colors.amber,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    business.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle:
                      business.description != null
                          ? Text(
                            business.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                          : null,
                  trailing: const Icon(Icons.arrow_forward, size: 20),
                  onTap: () => _selectWorkspace(business),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddBusinessButton() {
    return Card(
      color: Colors.amber.shade100,
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final result = await showDialog<Business>(
            context: context,
            builder:
                (context) =>
                    const CreateBusinessDialog(type: BusinessType.business),
          );

          if (result != null && mounted) {
            // Перезагружаем список бизнесов
            final provider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            await provider.loadBusinesses();
            // Автоматически выбираем созданный бизнес
            await _selectWorkspace(result);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 48,
                color: Colors.amber,
              ),
              const SizedBox(height: 12),
              const Text(
                'Создать бизнес',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
