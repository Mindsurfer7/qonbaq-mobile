import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/pending_confirmations_provider.dart';

/// Нижняя панель для desktop версии с quick actions
/// 
/// Содержит:
/// - Задачи
/// - Согласования (с индикатором количества)
/// - Точки контроля (1, 2, 3)
/// - "Не забыть выполнить" (Заметки на ходу)
/// - Избранное
class DesktopBottomBar extends StatelessWidget {
  const DesktopBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildQuickActionButton(
              context,
              'Задачи',
              Icons.task_alt,
              Colors.teal,
              () => Navigator.of(context).pushNamed('/business/operational/tasks'),
            ),
            const SizedBox(width: 8),
            _buildApprovalsButton(context),
            const SizedBox(width: 8),
            _buildControlPointButton(context, '1', Colors.orange),
            const SizedBox(width: 4),
            _buildControlPointButton(context, '2', Colors.orange),
            const SizedBox(width: 4),
            _buildControlPointButton(context, '3', Colors.orange),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              context,
              'Не забыть выполнить',
              Icons.note_add,
              Colors.red,
              () => Navigator.of(context).pushNamed('/remember'),
            ),
            const Spacer(),
            _buildQuickActionButton(
              context,
              'Избранное',
              Icons.star,
              Colors.amber,
              () => Navigator.of(context).pushNamed('/favorites'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalsButton(BuildContext context) {
    return Consumer<PendingConfirmationsProvider>(
      builder: (context, provider, child) {
        final totalCount = provider.totalCount;
        final hasPending = provider.hasPending;
        
        return InkWell(
          onTap: () => Navigator.of(context).pushNamed('/approvals'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Colors.green,
                    ),
                    if (hasPending)
                      Positioned(
                        right: -8,
                        top: -8,
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
                              totalCount > 99 ? '99+' : '$totalCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                const Text(
                  'Согласования',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlPointButton(
    BuildContext context,
    String number,
    Color color,
  ) {
    return InkWell(
      onTap: () {
        // TODO: Реализовать переход к точкам контроля
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Точка контроля $number')),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.4),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 2),
              Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
