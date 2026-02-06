import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/invite_provider.dart';
import '../../domain/entities/business.dart';
import '../widgets/create_business_dialog.dart';
import '../widgets/voice_task_dialog.dart';
import '../../core/utils/constants.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/create_task.dart';
import 'package:flutter/services.dart';

/// Страница выбора workspace (семья или бизнес)
class WorkspaceSelectorPage extends StatefulWidget {
  const WorkspaceSelectorPage({super.key});

  @override
  State<WorkspaceSelectorPage> createState() => _WorkspaceSelectorPageState();
}

class _WorkspaceSelectorPageState extends State<WorkspaceSelectorPage>
    with SingleTickerProviderStateMixin {
  bool _showBusinessList = false; // Флаг для раскрытия списка бизнесов
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллер анимации
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Загружаем список бизнесов и создаем/загружаем инвайты при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      if (profileProvider.businesses == null && !profileProvider.isLoading) {
        profileProvider.loadBusinesses();
      }
      // Автоматически создаем/загружаем инвайты при первом открытии страницы
      final inviteProvider = Provider.of<InviteProvider>(
        context,
        listen: false,
      );
      // Сначала пытаемся загрузить существующие инвайты
      await inviteProvider.loadCurrentInvite();
      // Если инвайтов нет, создаем их через POST /api/invites
      if (inviteProvider.invitesList == null ||
          inviteProvider.invitesList!.invites.isEmpty) {
        await inviteProvider.createInviteLink();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectWorkspace(Business workspace) async {
    // Закрываем раскрытый список бизнесов, если он открыт
    if (_showBusinessList) {
      setState(() {
        _showBusinessList = false;
        _animationController.reverse();
      });
    }

    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.selectWorkspace(workspace);

    if (!mounted) return;

    // Переходим на главную страницу бизнеса
    context.go('/business');
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
    // Проверяем, является ли пользователь гостем
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.isGuest == true) {
      // Если гость, используем демо-бизнес из AuthProvider
      final guestBusiness = authProvider.guestBusiness;
      if (guestBusiness != null) {
        await _selectWorkspace(guestBusiness);
        return;
      }
    }

    // Отладочная информация
    debugPrint('=== Business Action Debug ===');
    debugPrint(
      'Всего бизнесов в провайдере: ${provider.businesses?.length ?? 0}',
    );
    if (provider.businesses != null) {
      debugPrint('Все бизнесы из провайдера:');
      for (var b in provider.businesses!) {
        debugPrint('  - ${b.name} (type: ${b.type}, id: ${b.id})');
      }
    }

    debugPrint(
      'Бизнесов в отфильтрованном списке (businessList): ${businessList.length}',
    );
    for (var b in businessList) {
      debugPrint(
        '  * В businessList: ${b.name} (type: ${b.type}, id: ${b.id})',
      );
    }

    if (businessList.isEmpty) {
      debugPrint(
        '→ Ветка: businessList.isEmpty -> открываю диалог создания бизнеса',
      );
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
    } else if (businessList.length == 1) {
      debugPrint(
        '→ Ветка: один бизнес в businessList -> сразу заходим в ${businessList.first.name} (${businessList.first.id})',
      );
      // Если один бизнес - сразу переходим внутрь
      await _selectWorkspace(businessList.first);
    } else {
      debugPrint(
        '→ Ветка: несколько бизнесов в businessList (${businessList.length}) -> раскрываю список',
      );
      // Если несколько бизнесов - показываем список с анимацией
      setState(() {
        _showBusinessList = !_showBusinessList;
        if (_showBusinessList) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  Future<void> _showInviteDialog(bool isFamily) async {
    final inviteProvider = Provider.of<InviteProvider>(context, listen: false);

    // Создаем/обновляем инвайты (POST /api/invites создает инвайты лениво)
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

    // Получаем нужный инвайт по типу
    final invite =
        isFamily ? inviteProvider.familyInvite : inviteProvider.businessInvite;

    if (invite != null) {
      // Используем ссылку из API (links.web или links.deepLink)
      final inviteLink =
          invite.links.web.isNotEmpty
              ? invite.links.web
              : AppConstants.buildInviteLink(invite.invite.code);

      // Всегда копируем ссылку в буфер обмена
      await Clipboard.setData(ClipboardData(text: inviteLink));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка скопирована в буфер обмена'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Если инвайт нужного типа не найден
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFamily
                  ? 'Семейный инвайт недоступен'
                  : 'Бизнес-инвайт недоступен. У вас нет прав для создания бизнес-инвайта.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
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
  //                 context.pop();
  //                 // Переходим на страницу "Не забыть" с результатом
  //                 context.go('/remember');
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
                  child: Consumer<InviteProvider>(
                    builder: (context, inviteProvider, child) {
                      final hasBusiness = inviteProvider.hasBusiness;
                      return Row(
                        children: [
                          Expanded(
                            child: _buildInviteButton(
                              title: 'Пригласить члена семьи',
                              icon: Icons.family_restroom,
                              color: Colors.green,
                              onTap: () => _showInviteDialog(true),
                              enabled: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInviteButton(
                              title: 'Пригласить коллегу',
                              icon: Icons.business,
                              color: Colors.blue,
                              onTap: () => _showInviteDialog(false),
                              enabled: hasBusiness,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Кнопки Семья/Бизнес (многофункциональные)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildActionButton(
                                  title: 'Семья',
                                  icon: Icons.people,
                                  color: Colors.green,
                                  onTap:
                                      () => _handleFamilyAction(
                                        familyBusiness,
                                        provider,
                                      ),
                                  screenHeight:
                                      MediaQuery.of(context).size.height,
                                  notificationCount:
                                      0, // TODO: заменить на данные из endpoint
                                  pinCount:
                                      3, // TODO: заменить на данные из endpoint
                                ),
                                const SizedBox(height: 12),
                                _buildVoiceMicrophoneButton(
                                  isFamily: true,
                                  familyBusiness: familyBusiness,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _buildActionButton(
                                  title: 'Бизнес',
                                  icon: Icons.business,
                                  color: Colors.blue,
                                  onTap:
                                      () => _handleBusinessAction(
                                        businessList,
                                        provider,
                                      ),
                                  screenHeight:
                                      MediaQuery.of(context).size.height,
                                  notificationCount:
                                      0, // TODO: заменить на данные из endpoint
                                  pinCount:
                                      5, // TODO: заменить на данные из endpoint
                                  onCreateBusinessTap: () async {
                                    final result = await showDialog<Business>(
                                      context: context,
                                      builder:
                                          (context) =>
                                              const CreateBusinessDialog(
                                                type: BusinessType.business,
                                              ),
                                    );

                                    if (result != null && mounted) {
                                      // Перезагружаем список бизнесов
                                      await provider.loadBusinesses();
                                      // Автоматически выбираем созданный бизнес
                                      await _selectWorkspace(result);
                                    }
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildVoiceMicrophoneButton(
                                  isFamily: false,
                                  businessList: businessList,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Раскрывающийся список бизнесов с анимацией
                      if (businessList.length > 1)
                        ClipRect(
                          child: SizeTransition(
                            sizeFactor: _expandAnimation,
                            axisAlignment: -1.0,
                            child: _buildAnimatedBusinessList(businessList),
                          ),
                        ),
                    ],
                  ),
                ),

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
    bool enabled = true,
  }) {
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
    final disabledColor = Colors.grey;
    final disabledDarkerColor = Colors.grey.shade700;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              enabled
                  ? [color, darkerColor]
                  : [disabledColor, disabledDarkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.6,
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
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double screenHeight,
    required int notificationCount,
    required int pinCount,
    VoidCallback? onCreateBusinessTap,
  }) {
    final darkerColor = Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
    // Высота кнопки - минимум треть экрана
    final buttonHeight = screenHeight / 3;
    return Container(
      height: buttonHeight,
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
        child: Stack(
          children: [
            // Основной контент кнопки
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Верхняя часть: иконка и название (центрированы)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Нижняя часть: индикаторы
                    Column(
                      children: [
                        // Индикатор уведомлений
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 20,
                            ),
                            Text(
                              notificationCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Индикатор PIN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.push_pin, color: Colors.white, size: 20),
                            Text(
                              pinCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Кнопка создания бизнеса в верхнем правом углу (только для бизнеса)
            if (onCreateBusinessTap != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onCreateBusinessTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Кнопка микрофона для голосового создания задачи
  Widget _buildVoiceMicrophoneButton({
    required bool isFamily,
    Business? familyBusiness,
    List<Business>? businessList,
  }) {
    return InkWell(
      onTap: () => _showVoiceTaskDialog(isFamily, familyBusiness, businessList),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFamily ? Colors.green.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFamily ? Colors.green.shade200 : Colors.blue.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              color: isFamily ? Colors.green.shade700 : Colors.blue.shade700,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Создать задачу',
              style: TextStyle(
                color: isFamily ? Colors.green.shade700 : Colors.blue.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Показывает диалог голосового создания задачи
  void _showVoiceTaskDialog(
    bool isFamily,
    Business? familyBusiness,
    List<Business>? businessList,
  ) {
    // Определяем businessId в зависимости от типа
    String? businessId;

    if (isFamily) {
      // Для семьи используем familyBusiness
      if (familyBusiness == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала создайте семью'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      businessId = familyBusiness.id;
    } else {
      // Для бизнеса используем первый бизнес из списка
      if (businessList == null || businessList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сначала создайте бизнес'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      businessId = businessList.first.id;
    }

    // Получаем зависимости из провайдеров
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    // Показываем диалог
    showDialog(
      context: context,
      builder:
          (context) => VoiceTaskDialog(
            businessId: businessId!,
            userRepository: userRepository,
            createTaskUseCase: createTaskUseCase,
          ),
    );
  }

  /// Виджет списка бизнесов с анимацией (раскрывается под кнопкой)
  Widget _buildAnimatedBusinessList(List<Business> businesses) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...businesses.map((business) {
            return InkWell(
              onTap: () => _selectWorkspace(business),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width:
                          businesses.indexOf(business) < businesses.length - 1
                              ? 1
                              : 0,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            business.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (business.description != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              business.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Временно закомментировано
  // Widget _buildBottomActionBar() {
  //   return Container(
  //     margin: const EdgeInsets.all(16),
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.grey.shade800,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceAround,
  //       children: [
  //         Expanded(
  //           child: _buildBottomActionItem(
  //             icon: Icons.add,
  //             label: 'Создать задачу',
  //             onTap: () {
  //               // Переход на создание задачи
  //               context.go('/tasks');
  //             },
  //           ),
  //         ),
  //         Expanded(
  //           child: _buildBottomActionItem(
  //             icon: Icons.edit_note,
  //             label: 'Не забыть',
  //             onTap: () {
  //               context.go('/remember');
  //             },
  //           ),
  //         ),
  //         // Временно закомментировано
  //         // Expanded(
  //         //   child: _buildBottomActionItem(
  //         //     icon: Icons.mic,
  //         //     label: '',
  //         //     onTap: _showVoiceRecordDialog,
  //         //   ),
  //         // ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildBottomActionItem({
  //   required IconData icon,
  //   required String label,
  //   required VoidCallback onTap,
  // }) {
  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(8),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(icon, color: Colors.white, size: 20),
  //             if (label.isNotEmpty) ...[
  //               const SizedBox(width: 8),
  //               Text(
  //                 label,
  //                 style: const TextStyle(color: Colors.white, fontSize: 14),
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
