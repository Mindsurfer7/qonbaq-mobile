import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/workday_dialog.dart';

/// Верхняя панель для mobile версии
/// 
/// Содержит кнопки:
/// - Рабочий день
/// - Чаты
/// - Календарь
/// - Профиль
class MobileTopPanel extends StatelessWidget {
  const MobileTopPanel({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildButton(
              context,
              'Рабочий день',
              Icons.play_arrow,
              () => showDialog(
                context: context,
                builder: (c) => const WorkDayDialog(),
              ),
            ),
            _buildButton(
              context,
              'Чаты',
              Icons.chat,
              () => context.go('/chats_email'),
            ),
            _buildButton(
              context,
              'Календарь',
              Icons.calendar_today,
              () => context.go('/calendar'),
            ),
            _buildButton(
              context,
              'Профиль',
              Icons.person,
              () => context.go('/profile_settings'),
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
