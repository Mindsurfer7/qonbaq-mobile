import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/invite_provider.dart';
import '../../domain/entities/business.dart';
import '../widgets/create_business_dialog.dart';
import '../widgets/voice_record_widget.dart';
import '../../core/services/voice_context.dart';
import 'package:flutter/services.dart';

/// Страница выбора workspace (семья или бизнес)
class WorkspaceSelectorPage extends StatefulWidget {
  const WorkspaceSelectorPage({super.key});

  @override
  State<WorkspaceSelectorPage> createState() => _WorkspaceSelectorPageState();
}

class _WorkspaceSelectorPageState extends State<WorkspaceSelectorPage> {
  int _selectedTab = 0; // 0 - Семья, 1 - Бизнес

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

  Future<void> _showInviteDialog(bool isFamily) async {
    final inviteProvider = Provider.of<InviteProvider>(context, listen: false);

    await inviteProvider.createInviteLink();

    if (!mounted) return;

    if (inviteProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(inviteProvider.error!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final inviteResult = inviteProvider.inviteResult;
    if (inviteResult != null) {
      // Копируем deep link в буфер обмена
      await Clipboard.setData(ClipboardData(text: inviteResult.links.deepLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка скопирована в буфер обмена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showVoiceRecordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: VoiceRecordWidget(
                context: VoiceContext.dontForget,
                onResultReceived: (result) {
                  Navigator.of(context).pop();
                  // Переходим на страницу "Не забыть" с результатом
                  Navigator.of(context).pushNamed('/remember');
                },
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                },
                style: VoiceRecordStyle.fullscreen,
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
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

          return Column(
            children: [
              // Кнопки приглашения
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInviteButton(
                        title: 'Пригласить члена семьи',
                        icon: Icons.family_restroom,
                        color: Colors.green,
                        onTap: () => _showInviteDialog(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInviteButton(
                        title: 'Пригласить коллегу',
                        icon: Icons.business,
                        color: Colors.blue,
                        onTap: () => _showInviteDialog(false),
                      ),
                    ),
                  ],
                ),
              ),

              // Вкладки Семья/Бизнес
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Семья',
                        icon: Icons.people,
                        isSelected: _selectedTab == 0,
                        color: Colors.green,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Бизнес',
                        icon: Icons.business,
                        isSelected: _selectedTab == 1,
                        color: Colors.blue,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Контент под вкладками - два столбца (Семья и Бизнес)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Столбец "Семья"
                      Expanded(child: _buildFamilyColumn(familyBusiness)),
                      const SizedBox(width: 12),
                      // Столбец "Бизнес"
                      Expanded(
                        child: _buildBusinessColumn(businessList, provider),
                      ),
                    ],
                  ),
                ),
              ),

              // Нижняя панель действий
              _buildBottomActionBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInviteButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, darkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
    return Container(
      decoration: BoxDecoration(
        gradient:
            isSelected
                ? LinearGradient(
                  colors: [color, darkerColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        color: isSelected ? null : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyColumn(Business? familyBusiness) {
    return Column(
      children: [
        // Flex-колонка с двумя элементами (flex-рядами)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Первый flex-ряд: иконка слева, цифра справа
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.notifications,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  Text(
                    '0', // TODO: заменить на данные из endpoint
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Второй flex-ряд: иконка слева, цифра справа
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.push_pin, color: Colors.red, size: 20),
                  Text(
                    '3', // TODO: заменить на данные из endpoint
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Кнопка выбора семьи
        if (familyBusiness != null)
          Expanded(child: _buildFamilyButton(familyBusiness))
        else
          Expanded(child: _buildAddFamilyButton()),
      ],
    );
  }

  Widget _buildBusinessColumn(
    List<Business> businessList,
    ProfileProvider provider,
  ) {
    return Column(
      children: [
        // Flex-колонка с двумя элементами (flex-рядами)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Первый flex-ряд: иконка слева, цифра справа
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.notifications,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  Text(
                    '0', // TODO: заменить на данные из endpoint
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Второй flex-ряд: иконка слева, цифра справа
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.push_pin, color: Colors.red, size: 20),
                  Text(
                    '5', // TODO: заменить на данные из endpoint
                    style: TextStyle(
                      color: Colors.brown.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Список бизнесов или кнопка создания
        if (businessList.isNotEmpty)
          Expanded(child: _buildBusinessList(businessList))
        else
          Expanded(child: _buildAddBusinessButton()),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _buildBottomActionItem(
              icon: Icons.add,
              label: 'Создать задачу',
              onTap: () {
                // Переход на создание задачи
                Navigator.of(context).pushNamed('/tasks');
              },
            ),
          ),
          Expanded(
            child: _buildBottomActionItem(
              icon: Icons.edit_note,
              label: 'Не забыть',
              onTap: () {
                Navigator.of(context).pushNamed('/remember');
              },
            ),
          ),
          Expanded(
            child: _buildBottomActionItem(
              icon: Icons.mic,
              label: '',
              onTap: _showVoiceRecordDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
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
