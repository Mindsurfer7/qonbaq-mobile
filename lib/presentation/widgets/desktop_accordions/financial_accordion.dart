import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Аккордеон для финансового блока
/// 
/// Содержит:
/// - Заявки на оплату
/// - Доходы - Расходы
class FinancialAccordion extends StatelessWidget {
  final String currentRoute;
  
  const FinancialAccordion({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSimpleItem(
          context,
          'Заявки на оплату',
          Icons.payment,
          Colors.blue,
          '/business/financial/payment_requests',
        ),
        _buildSimpleItem(
          context,
          'Доходы - Расходы',
          Icons.account_balance_wallet,
          Colors.green,
          '/business/financial/income_expense',
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
