import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../widgets/workday_dialog.dart';
import '../providers/profile_provider.dart';
import '../providers/pending_confirmations_provider.dart';
import '../providers/auth_provider.dart';
import '../../domain/entities/workday.dart';
import '../../core/utils/responsive_utils.dart';
import '../layouts/adaptive_shell.dart';

/// Главная страница бизнес-приложения
class BusinessMainPage extends StatefulWidget {
  const BusinessMainPage({super.key});

  @override
  State<BusinessMainPage> createState() => _BusinessMainPageState();
}

class _BusinessMainPageState extends State<BusinessMainPage> {
  String? _lastBusinessId;

  @override
  void initState() {
    super.initState();
    // Загружаем компании при инициализации страницы
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Загружаем компании, если они еще не загружены
      if (profileProvider.businesses == null && !profileProvider.isLoading) {
        await profileProvider.loadBusinesses();
      }

      // Проверяем, есть ли выбранный workspace
      if (!mounted) return;

      if (profileProvider.selectedWorkspace == null) {
        // Если workspace не выбран, перенаправляем на страницу выбора
        Navigator.of(context).pushReplacementNamed('/workspace-selector');
        return;
      }

      // Загружаем профиль с employment текущего пользователя
      if (authProvider.user != null) {
        await profileProvider.loadProfile(userId: authProvider.user!.id);
      }

      // Запускаем polling для pending confirmations
      final pendingProvider = Provider.of<PendingConfirmationsProvider>(
        context,
        listen: false,
      );
      final businessId = profileProvider.selectedBusiness?.id;
      _lastBusinessId = businessId;
      debugPrint(
        '🚀 BusinessMainPage: Запускаем polling для businessId: $businessId',
      );
      pendingProvider.startPolling(businessId: businessId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Обновляем polling при смене бизнеса
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final pendingProvider = Provider.of<PendingConfirmationsProvider>(
      context,
      listen: false,
    );
    final businessId = profileProvider.selectedBusiness?.id;

    // Обновляем только если businessId изменился
    if (_lastBusinessId != businessId) {
      debugPrint(
        '🔄 BusinessMainPage: Обновляем polling для нового businessId: $businessId (было: $_lastBusinessId)',
      );
      _lastBusinessId = businessId;
      pendingProvider.updateBusinessId(businessId);
    }
  }

  @override
  void dispose() {
    // Останавливаем polling при закрытии страницы
    final pendingProvider = Provider.of<PendingConfirmationsProvider>(
      context,
      listen: false,
    );
    pendingProvider.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // На desktop используем DesktopLayout через AdaptiveShell
    if (context.isDesktop) {
      return const AdaptiveShell(child: SizedBox.shrink());
    }
    
    // На mobile показываем обычный Scaffold
    return Scaffold(
      appBar: AppBar(
        title: Selector<ProfileProvider, String>(
          selector: (context, provider) {
            // Создаем ключ для пересоздания только при изменении workspace или familyBusiness
            final workspaceId = provider.selectedWorkspace?.id ?? '';
            final familyBusinessId = provider.familyBusiness?.id ?? '';
            return '$workspaceId|$familyBusinessId';
          },
          builder: (context, key, child) {
            final provider = Provider.of<ProfileProvider>(
              context,
              listen: false,
            );
            // Показываем "Семья" если выбран первый бизнес (семья), иначе "Бизнес"
            final isFamily =
                provider.selectedWorkspace != null &&
                provider.familyBusiness != null &&
                provider.selectedWorkspace!.id == provider.familyBusiness!.id;
            return Text(isFamily ? 'Семья' : 'Business Main');
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Главная / Сменить пространство',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/workspace-selector');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Профиль',
            onPressed: () {
              Navigator.of(context).pushNamed('/home');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Верхняя навигация
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Selector<ProfileProvider, WorkDayStatus?>(
                  selector: (context, provider) {
                    return provider.profile?.workDay?.status;
                  },
                  builder: (context, status, child) {
                    if (status == WorkDayStatus.started) {
                      // Когда день начат, показываем одну кнопку "Завершить / Пауза"
                      return _buildWorkDayButton(
                        context,
                        'Завершить / Пауза',
                        Icons.stop,
                        true,
                        onTap: () => _showWorkDayDialog(context),
                      );
                    } else if (status == WorkDayStatus.paused) {
                      // Когда день на паузе, показываем кнопку "Возобновить"
                      return _buildWorkDayButton(
                        context,
                        'Возобновить',
                        Icons.play_arrow,
                        false,
                        onTap: () => _showWorkDayDialog(context),
                      );
                    } else {
                      // Когда день не начат, показываем одну кнопку "Начать"
                      return _buildWorkDayButton(
                        context,
                        'Начать рабочий день',
                        Icons.play_arrow,
                        false,
                        onTap: () => _showWorkDayDialog(context),
                      );
                    }
                  },
                ),
                _buildTopNavItem(
                  context,
                  'Чаты, почта, телефония',
                  '/chats_email',
                  Icons.chat,
                ),
                _buildTopNavItem(
                  context,
                  'Календарь событий',
                  '/calendar',
                  Icons.calendar_today,
                ),
                _buildTopNavItem(
                  context,
                  'Мой профиль/настройки',
                  '/profile_settings',
                  Icons.settings,
                ),
              ],
            ),
          ),
          // Основной контент
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildBlockCard(
                  context,
                  'Операционный блок',
                  Colors.green,
                  '/business/operational',
                  Icons.business,
                ),
                _buildBlockCard(
                  context,
                  'Финансовый блок',
                  Colors.blue,
                  '/business/financial',
                  Icons.attach_money,
                ),
                _buildBlockCard(
                  context,
                  'Административно-хозяйственный блок',
                  Colors.grey,
                  '/business/admin',
                  Icons.admin_panel_settings,
                ),
                _buildBlockCard(
                  context,
                  'Аналитический блок',
                  Colors.amber,
                  '/business/analytics',
                  Icons.analytics,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBlockCard(
    BuildContext context,
    String title,
    Color color,
    String route,
    IconData icon,
  ) {
    return Card(
      color: color.withOpacity(0.2),
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 'Задачи', '/business/operational/tasks', Icons.task),
          _buildNavItem(
            context,
            'Согласования',
            '/approvals',
            Icons.check_circle,
          ),
          _buildNavItem(context, 'Заметки на ходу', '/remember', Icons.note),
          _buildNavItem(context, 'Избранное', '/favorites', Icons.star),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String label,
    String route,
    IconData icon,
  ) {
    // Для иконки согласований показываем специальный виджет с индикатором
    if (route == '/approvals') {
      return Selector<PendingConfirmationsProvider, int>(
        selector: (context, provider) => provider.totalCount,
        builder: (context, totalCount, child) {
          final provider = Provider.of<PendingConfirmationsProvider>(
            context,
            listen: false,
          );
          return InkWell(
            onTap: () => Navigator.of(context).pushNamed(route),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon),
                    if (provider.hasPending)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              totalCount > 99 ? '99+' : '$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    // Обычная иконка для остальных пунктов
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkDayButton(
    BuildContext context,
    String label,
    IconData icon,
    bool isStarted, {
    VoidCallback? onTap,
  }) {
    final color = isStarted ? Colors.red : Colors.green;
    
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Если день начат, показываем иконку паузы и красный квадрат
                if (isStarted)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.pause, size: 20, color: Colors.orange),
                      const SizedBox(width: 4),
                      Icon(icon, size: 20, color: color),
                    ],
                  )
                else
                  Icon(icon, size: 20, color: color),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNavItem(
    BuildContext context,
    String label,
    String? route,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap:
            onTap ??
            (route != null
                ? () => Navigator.of(context).pushNamed(route)
                : null),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 9),
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

  void _showWorkDayDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const WorkDayDialog());
  }
}
