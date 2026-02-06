import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final String currentRoute;
  
  const OperationalAccordion({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
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
        ),
        
        // Задачи
        _buildSimpleItem(
          context,
          'Задачи',
          Icons.task,
          Colors.orange,
          '/business/operational/tasks',
        ),
        
        // Бизнес-процессы
        _buildSimpleItem(
          context,
          'Бизнес-процессы',
          Icons.settings,
          Colors.purple,
          '/business/operational/business_processes',
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
        ),
        
        const Divider(height: 24),
        
        // Настройка группы
        _buildSimpleItem(
          context,
          'Настройка группы',
          Icons.group_work,
          Colors.grey,
          '/organizational_structure',
        ),
        
        // Настройка телефонии
        _buildSimpleItem(
          context,
          'Настройка телефонии',
          Icons.phone,
          Colors.grey,
          '/phone_settings',
        ),
        
        // Права доступа сотрудников
        _buildSimpleItem(
          context,
          'Права доступа',
          Icons.admin_panel_settings,
          Colors.grey,
          '/roles-assignment',
        ),
      ],
    );
  }

  Widget _buildSimpleItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    final isActive = currentRoute.startsWith(route);
    
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
      onTap: () {
        debugPrint('🔗 Navigating to: $route');
        context.go(route);
      },
    );
  }

  Widget _buildExpandableSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<_NavItem> items,
  ) {
    // Проверяем, есть ли активный item в этой секции
    final hasActiveItem = items.any((item) => currentRoute.startsWith(item.route));
    
    return ExpansionTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: hasActiveItem ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      initiallyExpanded: hasActiveItem,
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.only(left: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      children: items.map((item) {
        final isActive = currentRoute.startsWith(item.route);
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
          onTap: () {
            debugPrint('🔗 Navigating to: ${item.route}');
            context.go(item.route);
          },
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
