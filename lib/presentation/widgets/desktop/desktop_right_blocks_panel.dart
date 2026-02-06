import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/desktop_navigation_provider.dart';

/// Правая панель для desktop версии с 4 основными блоками
/// 
/// Содержит кнопки:
/// - Операционный блок (зеленый)
/// - Финансовый блок (синий)
/// - Административно-хозяйственный блок (серый)
/// - Аналитический блок (желтый)
class DesktopRightBlocksPanel extends StatelessWidget {
  const DesktopRightBlocksPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Основные блоки',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Consumer<DesktopNavigationProvider>(
                builder: (context, navProvider, child) {
                  return Column(
                    children: [
                      _buildBlockButton(
                        context,
                        'Операции',
                        Icons.settings,
                        Colors.green,
                        'operational',
                        navProvider.currentBlock == 'operational',
                        () => context.go('/business/operational/crm'),
                      ),
                      const SizedBox(height: 12),
                      _buildBlockButton(
                        context,
                        'Финансы',
                        Icons.attach_money,
                        Colors.blue,
                        'financial',
                        navProvider.currentBlock == 'financial',
                        () => context.go('/business/financial/payment_requests'),
                      ),
                      const SizedBox(height: 12),
                      _buildBlockButton(
                        context,
                        'АХО',
                        Icons.build,
                        Colors.grey,
                        'admin',
                        navProvider.currentBlock == 'admin',
                        () => context.go('/business/admin/document_management'),
                      ),
                      const SizedBox(height: 12),
                      _buildBlockButton(
                        context,
                        'Аналитика',
                        Icons.analytics,
                        Colors.amber,
                        'analytics',
                        navProvider.currentBlock == 'analytics',
                        () => context.go('/business/analytics'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String blockId,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive 
            ? color.withOpacity(0.2) 
            : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
              ? color.withOpacity(0.5) 
              : color.withOpacity(0.1),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
