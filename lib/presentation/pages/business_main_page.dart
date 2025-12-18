import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/workday_dialog.dart';
import '../providers/profile_provider.dart';

/// Главная страница бизнес-приложения
class BusinessMainPage extends StatefulWidget {
  const BusinessMainPage({super.key});

  @override
  State<BusinessMainPage> createState() => _BusinessMainPageState();
}

class _BusinessMainPageState extends State<BusinessMainPage> {
  @override
  void initState() {
    super.initState();
    // Загружаем компании при инициализации страницы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      // Загружаем компании, если они еще не загружены
      if (provider.businesses == null && !provider.isLoading) {
        provider.loadBusinesses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Main'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Главная',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/business');
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
                _buildTopNavItem(
                  context,
                  'Начать рабочий день',
                  null,
                  Icons.play_arrow,
                  onTap: () => _showWorkDayDialog(context),
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
          _buildNavItem(context, 'Задачи', '/tasks', Icons.task),
          _buildNavItem(
            context,
            'Согласования',
            '/approvals',
            Icons.check_circle,
          ),
          _buildNavItem(
            context,
            'Не забыть выполнить',
            '/remember',
            Icons.notifications,
          ),
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

  Widget _buildTopNavItem(
    BuildContext context,
    String label,
    String? route,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? (route != null ? () => Navigator.of(context).pushNamed(route) : null),
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
    showDialog(
      context: context,
      builder: (context) => const WorkDayDialog(),
    );
  }
}
