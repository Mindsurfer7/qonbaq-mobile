import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/desktop_navigation_provider.dart';

/// Аккордеон для операционного блока
/// 
/// Содержит:
/// - CRM (с подпунктами: CRM, Управление услугами)
/// - Задачи
/// - Бизнес-процессы
/// - ERP (с подпунктами: Строительство, Торговля, Логистика, Сфера услуг)
/// - Настройка группы
/// - Настройка телефонии
/// - Права доступа сотрудников
class OperationalAccordion extends StatelessWidget {
  const OperationalAccordion({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopNavigationProvider>(
      builder: (context, navProvider, child) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // CRM
            _buildExpandableSection(
              context,
              'CRM',
              Icons.people,
              Colors.blue,
              [
                _NavItem(
                  'CRM',
                  '/business/operational/crm',
                  Icons.people,
                ),
                _NavItem(
                  'Управление услугами',
                  '/business/operational/services-admin',
                  Icons.room_service,
                ),
              ],
              navProvider,
            ),
            
            // Задачи
            _buildSimpleItem(
              context,
              'Задачи',
              Icons.task,
              Colors.orange,
              '/business/operational/tasks',
              navProvider,
            ),
            
            // Бизнес-процессы
            _buildSimpleItem(
              context,
              'Бизнес-процессы',
              Icons.settings,
              Colors.purple,
              '/business/operational/business_processes',
              navProvider,
            ),
            
            // ERP
            _buildExpandableSection(
              context,
              'ERP',
              Icons.build,
              Colors.green,
              [
                _NavItem(
                  'Строительство',
                  '/business/operational/construction',
                  Icons.construction,
                ),
                _NavItem(
                  'Торговля',
                  '/business/operational/trade',
                  Icons.shopping_cart,
                ),
                _NavItem(
                  'Логистика',
                  '/business/operational/logistics',
                  Icons.local_shipping,
                ),
                _NavItem(
                  'Сфера услуг',
                  '/business/operational/services',
                  Icons.room_service,
                ),
              ],
              navProvider,
            ),
            
            const Divider(height: 24),
            
            // Настройка группы
            _buildSimpleItem(
              context,
              'Настройка группы',
              Icons.group_work,
              Colors.grey,
              '/organizational_structure',
              navProvider,
            ),
            
            // Настройка телефонии
            _buildSimpleItem(
              context,
              'Настройка телефонии',
              Icons.phone,
              Colors.grey,
              '/phone_settings',
              navProvider,
            ),
            
            // Права доступа сотрудников
            _buildSimpleItem(
              context,
              'Права доступа',
              Icons.admin_panel_settings,
              Colors.grey,
              '/roles-assignment',
              navProvider,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimpleItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
    DesktopNavigationProvider navProvider,
  ) {
    final isActive = navProvider.currentRoute == route;
    
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isActive,
      selectedTileColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      dense: true,
      onTap: () => navProvider.navigateTo(route),
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_NavItem> items,
    DesktopNavigationProvider navProvider,
  ) {
    return ExpansionTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.only(left: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      children: items.map((item) {
        final isActive = navProvider.currentRoute == item.route;
        return ListTile(
          leading: Icon(item.icon, color: color, size: 18),
          title: Text(
            item.title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isActive,
          selectedTileColor: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
          onTap: () => navProvider.navigateTo(item.route),
        );
      }).toList(),
    );
  }
}

class _NavItem {
  final String title;
  final String route;
  final IconData icon;

  _NavItem(this.title, this.route, this.icon);
}
