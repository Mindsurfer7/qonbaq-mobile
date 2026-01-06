import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/profile_provider.dart';
import '../providers/invite_provider.dart';
import '../../domain/entities/business.dart';
import '../widgets/create_business_dialog.dart';
// Временно закомментировано
// import '../widgets/voice_record_widget.dart';
// import '../../core/services/voice_context.dart';
import 'package:flutter/services.dart';

/// Страница выбора workspace (семья или бизнес)
class WorkspaceSelectorPage extends StatefulWidget {
  const WorkspaceSelectorPage({super.key});

  @override
  State<WorkspaceSelectorPage> createState() => _WorkspaceSelectorPageState();
}

class _WorkspaceSelectorPageState extends State<WorkspaceSelectorPage> {
  bool _showBusinessList = false; // Флаг для раскрытия списка бизнесов

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

  /// Обработка действия для кнопки "Семья"
  Future<void> _handleFamilyAction(
    Business? familyBusiness,
    ProfileProvider provider,
  ) async {
    if (familyBusiness != null) {
      // Если есть семья - сразу выбираем и переходим
      await _selectWorkspace(familyBusiness);
    } else {
      // Если нет семьи - показываем диалог создания
      final result = await showDialog<Business>(
        context: context,
        builder:
            (context) => const CreateBusinessDialog(type: BusinessType.family),
      );

      if (result != null && mounted) {
        // Перезагружаем список бизнесов
        await provider.loadBusinesses();
        // Автоматически выбираем созданный бизнес
        await _selectWorkspace(result);
      }
    }
  }

  /// Обработка действия для кнопки "Бизнес"
  Future<void> _handleBusinessAction(
    List<Business> businessList,
    ProfileProvider provider,
  ) async {
    if (businessList.isNotEmpty) {
      // Если есть бизнесы - выбираем нулевой элемент
      await _selectWorkspace(businessList[0]);
    } else {
      // Если нет бизнесов - показываем диалог создания
      final result = await showDialog<Business>(
        context: context,
        builder:
            (context) =>
                const CreateBusinessDialog(type: BusinessType.business),
      );

      if (result != null && mounted) {
        // Перезагружаем список бизнесов
        await provider.loadBusinesses();
        // Автоматически выбираем созданный бизнес
        await _selectWorkspace(result);
      }
    }
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
      // Используем веб-ссылку вместо deep link
      final inviteLink = inviteResult.links.web;

      // На веб и macOS - копируем ссылку в буфер обмена
      // (на macOS в share sheet нет кнопки копирования)
      final isMacOS =
          !kIsWeb && (Theme.of(context).platform == TargetPlatform.macOS);
      if (kIsWeb || isMacOS) {
        await Clipboard.setData(ClipboardData(text: inviteLink));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ссылка скопирована в буфер обмена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // На мобильных платформах (iOS/Android) - используем Share API с веб-ссылкой
        try {
          await Share.share(
            inviteLink,
            subject: isFamily ? 'Приглашение в семью' : 'Приглашение в бизнес',
          );
        } catch (e) {
          // Если Share API недоступен, копируем в буфер обмена
          await Clipboard.setData(ClipboardData(text: inviteLink));
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
    }
  }

  // Временно закомментировано
  // void _showVoiceRecordDialog() {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (context) => Dialog(
  //           child: Container(
  //             padding: const EdgeInsets.all(24),
  //             child: VoiceRecordWidget(
  //               context: VoiceContext.dontForget,
  //               onResultReceived: (result) {
  //                 Navigator.of(context).pop();
  //                 // Переходим на страницу "Не забыть" с результатом
  //                 Navigator.of(context).pushNamed('/remember');
  //               },
  //               onError: (error) {
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   SnackBar(content: Text(error), backgroundColor: Colors.red),
  //                 );
  //               },
  //               style: VoiceRecordStyle.fullscreen,
  //             ),
  //           ),
  //         ),
  //   );
  // }

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

          return SingleChildScrollView(
            child: Column(
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

                // Кнопки Семья/Бизнес (многофункциональные)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          title: 'Семья',
                          icon: Icons.people,
                          color: Colors.green,
                          onTap:
                              () =>
                                  _handleFamilyAction(familyBusiness, provider),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          title: 'Бизнес',
                          icon: Icons.business,
                          color: Colors.blue,
                          onTap:
                              () =>
                                  _handleBusinessAction(businessList, provider),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Индикаторы и плашечка "Показать все" для бизнеса
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Индикаторы семьи
                      Expanded(child: _buildIndicatorsColumn(isFamily: true)),
                      const SizedBox(width: 12),
                      // Индикаторы бизнеса
                      Expanded(
                        child: _buildIndicatorsColumn(
                          isFamily: false,
                          businessList: businessList,
                        ),
                      ),
                    ],
                  ),
                ),

                // Раскрывающийся список бизнесов
                if (_showBusinessList && businessList.length > 1) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildBusinessList(businessList),
                  ),
                ],

                // Нижняя панель действий
                // _buildBottomActionBar(),
              ],
            ),
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

  Widget _buildActionButton({
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
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

  Widget _buildIndicatorsColumn({
    required bool isFamily,
    List<Business>? businessList,
  }) {
    return Column(
      children: [
        // Индикаторы (колокольчик и пин)
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
                  Icon(Icons.notifications, color: Colors.black, size: 20),
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
                  Icon(Icons.push_pin, color: Colors.black, size: 20),
                  Text(
                    isFamily
                        ? '3'
                        : '5', // TODO: заменить на данные из endpoint
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
        // Плашечка "Показать все" для бизнеса (если бизнесов > 1)
        if (!isFamily && businessList != null && businessList.length > 1) ...[
          const SizedBox(height: 12),
          _buildShowAllButton(businessList),
        ],
      ],
    );
  }

  Widget _buildShowAllButton(List<Business> businessList) {
    return InkWell(
      onTap: () {
        setState(() {
          _showBusinessList = !_showBusinessList;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showBusinessList ? 'Скрыть список' : 'Показать все',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showBusinessList ? Icons.expand_less : Icons.expand_more,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ],
        ),
      ),
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
          // Временно закомментировано
          // Expanded(
          //   child: _buildBottomActionItem(
          //     icon: Icons.mic,
          //     label: '',
          //     onTap: _showVoiceRecordDialog,
          //   ),
          // ),
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

  Widget _buildBusinessList(List<Business> businesses) {
    return Card(
      color: Colors.amber.shade50,
      elevation: 2,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
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
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: businesses.length,
                itemBuilder: (context, index) {
                  final business = businesses[index];
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
