import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../providers/theme_provider.dart';
import '../workday_dialog.dart';
import '../../../domain/entities/workday.dart';

/// Верхняя панель для desktop версии
/// 
/// Содержит:
/// - Логотип приложения слева
/// - Кнопки действий в центре (начать рабочий день, чаты, календарь, орг структура)
/// - Аватарку и имя пользователя справа
/// - Переключатель темы
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Логотип
            _buildLogo(context),
            const SizedBox(width: 32),
            
            // Кнопки действий в центре
            Expanded(
              child: _buildActionButtons(context),
            ),
            
            // Правая часть: аватарка и тема
            _buildUserSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Q',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'QonbaQ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWorkDayButton(context),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          'Чаты',
          Icons.chat_bubble_outline,
          () => context.go('/chats_email'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          'Календарь',
          Icons.calendar_today,
          () => context.go('/calendar'),
        ),
        const SizedBox(width: 12),
        _buildActionButton(
          context,
          'Орг структура',
          Icons.account_tree,
          () => context.go('/organizational_structure'),
        ),
      ],
    );
  }

  Widget _buildWorkDayButton(BuildContext context) {
    return Selector<ProfileProvider, WorkDayStatus?>(
      selector: (context, provider) => provider.profile?.workDay?.status,
      builder: (context, status, child) {
        final isStarted = status == WorkDayStatus.started;
        final isPaused = status == WorkDayStatus.paused;
        
        String label;
        IconData icon;
        Color color;
        
        if (isStarted) {
          label = 'Завершить / Пауза';
          icon = Icons.stop;
          color = Colors.red;
        } else if (isPaused) {
          label = 'Возобновить';
          icon = Icons.play_arrow;
          color = Colors.orange;
        } else {
          label = 'Начать рабочий день';
          icon = Icons.play_arrow;
          color = Colors.green;
        }
        
        return _buildActionButton(
          context,
          label,
          icon,
          () => _showWorkDayDialog(context),
          color: color,
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: buttonColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: buttonColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: buttonColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: buttonColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        // Переключатель темы
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              ),
              tooltip: themeProvider.isDarkMode 
                ? 'Светлая тема' 
                : 'Темная тема',
              onPressed: () => themeProvider.toggleTheme(),
            );
          },
        ),
        
        const SizedBox(width: 16),
        
        // Аватарка и имя пользователя
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final profile = profileProvider.profile;
            
            // Формируем displayName из данных профиля
            String displayName = 'Пользователь';
            if (profile != null) {
              final firstName = profile.user.firstName ?? profile.employeeData.firstName;
              final lastName = profile.user.lastName ?? profile.employeeData.lastName;
              
              if (firstName != null && lastName != null) {
                displayName = '$firstName $lastName';
              } else if (firstName != null) {
                displayName = firstName;
              } else if (lastName != null) {
                displayName = lastName;
              }
            }
            
            return InkWell(
              onTap: () => context.go('/profile_settings'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        displayName.isNotEmpty 
                          ? displayName[0].toUpperCase() 
                          : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showWorkDayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WorkDayDialog(),
    );
  }
}
