import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Аккордеон для административно-хозяйственного блока
/// 
/// Содержит:
/// - Документооборот (с подпунктом: Карточка сотрудника)
/// - Основные средства
/// - Кадровые документы
/// - Штатное расписание
/// - Табель учета рабочего времени
class AdminAccordion extends StatelessWidget {
  final String currentRoute;
  
  const AdminAccordion({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Документооборот
        _buildSimpleItem(
          context,
          'Документооборот',
          Icons.description,
          Colors.blue,
          '/business/admin/document_management',
        ),
        
        // Основные средства
        _buildSimpleItem(
          context,
          'Основные средства',
          Icons.business,
          Colors.green,
          '/business/admin/fixed_assets',
        ),
        
        // Кадровые документы
        _buildSimpleItem(
          context,
          'Кадровые документы',
          Icons.folder_shared,
          Colors.purple,
          '/business/admin/hr_documents',
        ),
        
        // Штатное расписание
        _buildSimpleItem(
          context,
          'Штатное расписание',
          Icons.calendar_view_month,
          Colors.orange,
          '/business/admin/staff_schedule',
        ),
        
        // Табель учета рабочего времени
        _buildSimpleItem(
          context,
          'Табель',
          Icons.access_time,
          Colors.teal,
          '/business/admin/timesheet',
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
}
