import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/utils/user_display_name_formatter.dart';
import '../../domain/repositories/chat_repository.dart';
import '../pages/chat_detail_page.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Виджет для отображения информации о пользователе с иконкой чата
class UserInfoRow extends StatelessWidget {
  final ProfileUser? user;
  final String label;
  final IconData icon;
  final ChatRepository? chatRepository;
  final bool showChatButton;

  const UserInfoRow({
    super.key,
    required this.user,
    required this.label,
    required this.icon,
    this.chatRepository,
    this.showChatButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) return const SizedBox.shrink();

    final userName = UserDisplayNameFormatter.getUserDisplayName(user!);
    final userId = user!.id;
    final canOpenChat = chatRepository != null && showChatButton;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (canOpenChat)
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline),
                        iconSize: 20,
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _openChat(context, userId, userName),
                        tooltip: 'Открыть чат',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(BuildContext context, String userId, String userName) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Не открываем чат с самим собой
    if (currentUserId != null && currentUserId == userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя начать чат с самим собой')),
      );
      return;
    }

    final repository = chatRepository;
    if (repository == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          interlocutorName: userName,
          interlocutorId: userId,
          chatRepository: repository,
        ),
      ),
    );
  }
}
