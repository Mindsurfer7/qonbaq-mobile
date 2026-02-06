import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/desktop_navigation_provider.dart';

/// Аккордеон для финансового блока
/// 
/// Содержит:
/// - Заявки на оплату
/// - Доходы - Расходы
class FinancialAccordion extends StatelessWidget {
  const FinancialAccordion({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DesktopNavigationProvider>(
      builder: (context, navProvider, child) {
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildSimpleItem(
              context,
              'Заявки на оплату',
              Icons.payment,
              Colors.blue,
              '/business/financial/payment_requests',
              navProvider,
            ),
            _buildSimpleItem(
              context,
              'Доходы - Расходы',
              Icons.account_balance_wallet,
              Colors.green,
              '/business/financial/income_expense',
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
}
