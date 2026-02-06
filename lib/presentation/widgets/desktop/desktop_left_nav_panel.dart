import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/desktop_navigation_provider.dart';
import '../desktop_accordions/operational_accordion.dart';
import '../desktop_accordions/financial_accordion.dart';
import '../desktop_accordions/admin_accordion.dart';
import '../desktop_accordions/analytics_accordion.dart';

/// Левая навигационная панель для desktop версии
/// 
/// Отображает динамические аккордеоны в зависимости от выбранного блока:
/// - Операционный блок → OperationalAccordion
/// - Финансовый блок → FinancialAccordion
/// - Админ-хоз блок → AdminAccordion
/// - Аналитика → AnalyticsAccordion
class DesktopLeftNavPanel extends StatelessWidget {
  final String currentRoute;
  
  const DesktopLeftNavPanel({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopNavigationProvider>(
      builder: (context, navProvider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: navProvider.isLeftPanelCollapsed ? 60 : 250,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, navProvider),
              Expanded(
                child: navProvider.isLeftPanelCollapsed
                    ? _buildCollapsedView()
                    : _buildExpandedView(navProvider.currentBlock, currentRoute),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DesktopNavigationProvider navProvider,
  ) {
    final blockTitle = _getBlockTitle(navProvider.currentBlock);
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!navProvider.isLeftPanelCollapsed) ...[
            Expanded(
              child: Text(
                blockTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          IconButton(
            icon: Icon(
              navProvider.isLeftPanelCollapsed
                  ? Icons.chevron_right
                  : Icons.chevron_left,
            ),
            tooltip: navProvider.isLeftPanelCollapsed 
              ? 'Развернуть панель' 
              : 'Свернуть панель',
            onPressed: () => navProvider.toggleLeftPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(String currentBlock, String currentRoute) {
    switch (currentBlock) {
      case 'operational':
        return OperationalAccordion(currentRoute: currentRoute);
      case 'financial':
        return FinancialAccordion(currentRoute: currentRoute);
      case 'admin':
        return AdminAccordion(currentRoute: currentRoute);
      case 'analytics':
        return const AnalyticsAccordion();
      default:
        return OperationalAccordion(currentRoute: currentRoute);
    }
  }

  Widget _buildCollapsedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu,
            size: 32,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  String _getBlockTitle(String block) {
    switch (block) {
      case 'operational':
        return 'Операционный блок';
      case 'financial':
        return 'Финансовый блок';
      case 'admin':
        return 'Админ-хоз блок';
      case 'analytics':
        return 'Аналитика';
      default:
        return 'Навигация';
    }
  }
}
