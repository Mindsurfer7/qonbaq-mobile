import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/desktop_navigation_provider.dart';

/// Аккордеон для административно-хозяйственного блока
/// 
/// Содержит:
/// - Документооборот (с подпунктом: Карточка сотрудника)
/// - Подотчет (с подпунктом: Карточка ОС)
/// - Кадровые документы
/// - Штатное расписание
/// - Табель учета рабочего времени
class AdminAccordion extends StatelessWidget {
  const AdminAccordion({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopNavigationProvider>(
      builder: (context, navProvider, child) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // Документооборот
            _buildExpandableSection(
              context,
              'Документооборот',
              Icons.description,
              Colors.blue,
              [
                _NavItem(
                  'Карточка сотрудника',
                  '/business/admin/document_management/employee_card',
                  Icons.badge,
                ),
              ],
              navProvider,
            ),
            
            // Подотчет
            _buildExpandableSection(
              context,
              'Подотчет',
              Icons.account_balance,
              Colors.green,
              [
                _NavItem(
                  'Основные средства',
                  '/business/admin/fixed_assets',
                  Icons.business,
                ),
              ],
              navProvider,
            ),
            
            // Кадровые документы
            _buildSimpleItem(
              context,
              'Кадровые документы',
              Icons.folder_shared,
              Colors.purple,
              '/business/admin/hr_documents',
              navProvider,
            ),
            
            // Штатное расписание
            _buildSimpleItem(
              context,
              'Штатное расписание',
              Icons.calendar_view_month,
              Colors.orange,
              '/business/admin/staff_schedule',
              navProvider,
            ),
            
            // Табель учета рабочего времени
            _buildSimpleItem(
              context,
              'Табель',
              Icons.access_time,
              Colors.teal,
              '/business/admin/timesheet',
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
