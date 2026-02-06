import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../providers/desktop_navigation_provider.dart';
import '../../pages/operational_block_page.dart';
import '../../pages/financial_block_page.dart';
import '../../pages/admin_block_page.dart';
import '../../pages/analytics_block_page.dart';
import '../../pages/crm_page.dart';
import '../../pages/operational_tasks_page.dart';
import '../../pages/business_processes_page.dart';
import '../../pages/construction_page.dart';
import '../../pages/services_admin_page.dart';
import '../../pages/payment_requests_page.dart';
import '../../pages/income_expense_page.dart';
import '../../pages/document_management_page.dart';
import '../../pages/fixed_assets_page.dart';
import '../../pages/hr_documents_page.dart';
import '../../pages/staff_schedule_page.dart';
import '../../pages/timesheet_page.dart';

/// Desktop Navigator - управляет отображением контента в центральной части desktop layout
/// 
/// На основе currentRoute из DesktopNavigationProvider показывает соответствующую страницу
class DesktopNavigator extends StatelessWidget {
  const DesktopNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    // На mobile не используется
    if (!context.isDesktop) {
      return const SizedBox.shrink();
    }

    return Consumer<DesktopNavigationProvider>(
      builder: (context, navProvider, child) {
        final route = navProvider.currentRoute;
        
        // Если маршрут не задан, показываем дефолтную страницу для текущего блока
        if (route == null) {
          return _getDefaultPageForBlock(navProvider.currentBlock);
        }
        
        // Показываем страницу по маршруту
        return _getPageForRoute(route);
      },
    );
  }

  Widget _getDefaultPageForBlock(String block) {
    switch (block) {
      case 'operational':
        return const OperationalBlockPage();
      case 'financial':
        return const FinancialBlockPage();
      case 'admin':
        return const AdminBlockPage();
      case 'analytics':
        return const AnalyticsBlockPage();
      default:
        return const OperationalBlockPage();
    }
  }

  Widget _getPageForRoute(String route) {
    // Операционный блок
    if (route == '/business/operational/crm') {
      return const CrmPage();
    }
    if (route == '/business/operational/tasks') {
      return const OperationalTasksPage();
    }
    if (route == '/business/operational/business_processes') {
      return const BusinessProcessesPage();
    }
    if (route == '/business/operational/construction') {
      return const ConstructionPage();
    }
    if (route == '/business/operational/services-admin') {
      return const ServicesAdminPage();
    }
    
    // Финансовый блок
    if (route == '/business/financial/payment_requests') {
      return const PaymentRequestsPage();
    }
    if (route == '/business/financial/income_expense') {
      return const IncomeExpensePage();
    }
    
    // Админ-хоз блок
    if (route == '/business/admin/document_management') {
      return const DocumentManagementPage();
    }
    if (route == '/business/admin/fixed_assets') {
      return const FixedAssetsPage();
    }
    if (route == '/business/admin/hr_documents') {
      return const HrDocumentsPage();
    }
    if (route == '/business/admin/staff_schedule') {
      return const StaffSchedulePage();
    }
    if (route == '/business/admin/timesheet') {
      return const TimesheetPage();
    }
    
    // Если маршрут не найден, показываем placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Страница в разработке',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Route: $route',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
