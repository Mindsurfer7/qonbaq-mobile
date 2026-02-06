import 'package:flutter/material.dart';

/// Toolbar для страниц в desktop версии
/// Заменяет AppBar и размещается в верхней части контентной области
/// 
/// Содержит:
/// - Заголовок страницы
/// - Кнопки действий (например: +, Refresh, Filter)
class PageToolbar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const PageToolbar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}
