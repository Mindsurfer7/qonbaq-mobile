import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/pending_confirmations_provider.dart';

/// Нижняя панель для mobile версии
/// 
/// Содержит кнопки:
/// - Главная
/// - Задачи
/// - Согласования (с индикатором количества)
/// - Заметки на ходу
/// - Избранное
class MobileBottomPanel extends StatelessWidget {
  const MobileBottomPanel({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildButton(
              context,
              'Главная',
              Icons.home,
              () => context.go('/business'),
            ),
            _buildButton(
              context,
              'Задачи',
              Icons.task,
              () => context.go('/business/operational/tasks'),
            ),
            _buildApprovalsButton(context),
            _buildButton(
              context,
              'Заметки',
              Icons.note,
              () => context.go('/remember'),
            ),
            _buildButton(
              context,
              'Избранное',
              Icons.star,
              () => context.go('/favorites'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () {
          final currentRoute = GoRouterState.of(context).uri.path;
          debugPrint('🖱️ [MobileBottomPanel] Нажата кнопка: "$label"');
          debugPrint('📍 [MobileBottomPanel] Текущий route: $currentRoute');
          onTap();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final newRoute = GoRouterState.of(context).uri.path;
            debugPrint('✅ [MobileBottomPanel] После навигации route: $newRoute');
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildApprovalsButton(BuildContext context) {
    return Expanded(
      child: Consumer<PendingConfirmationsProvider>(
        builder: (context, provider, child) {
          final count = provider.totalCount;
          
          return InkWell(
            onTap: () {
              final currentRoute = GoRouterState.of(context).uri.path;
              const targetRoute = '/approvals';
              debugPrint('🖱️ [MobileBottomPanel] Нажата кнопка: "Согласования" (count: $count)');
              debugPrint('📍 [MobileBottomPanel] Текущий route: $currentRoute');
              debugPrint('🎯 [MobileBottomPanel] Целевой route: $targetRoute');
              context.go(targetRoute);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final newRoute = GoRouterState.of(context).uri.path;
                debugPrint('✅ [MobileBottomPanel] После навигации route: $newRoute');
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Согласования',
                        style: TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (count > 0)
                    Positioned(
                      right: 0,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            count > 99 ? '99+' : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
