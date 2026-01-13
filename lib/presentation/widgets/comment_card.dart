import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/utils/date_time_formatter.dart';
import '../../core/utils/user_display_name_formatter.dart';
import '../../domain/repositories/chat_repository.dart';
import '../pages/chat_detail_page.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'comment_item.dart';

/// Виджет для отображения одного комментария
class CommentCard extends StatelessWidget {
  final CommentItem comment;
  final VoidCallback onDelete;
  final ChatRepository? chatRepository;
  final bool showChatButton;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onDelete,
    this.chatRepository,
    this.showChatButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final commentUser = comment.user;
    final canOpenChat = commentUser != null && chatRepository != null && showChatButton;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          child: Text(
            commentUser != null
                ? UserDisplayNameFormatter.getUserDisplayName(commentUser)
                    .substring(0, 1)
                    .toUpperCase()
                : '?',
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                commentUser != null
                    ? UserDisplayNameFormatter.getUserDisplayName(commentUser)
                    : 'Пользователь',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (canOpenChat)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                iconSize: 18,
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _openChat(context, commentUser),
                tooltip: 'Открыть чат',
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(comment.text),
            const SizedBox(height: 8),
            Text(
              DateTimeFormatter.formatDateTime(comment.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Удалить',
        ),
      ),
    );
  }

  void _openChat(BuildContext context, ProfileUser user) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Не открываем чат с самим собой
    if (currentUserId != null && currentUserId == user.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя начать чат с самим собой')),
      );
      return;
    }

    final repository = chatRepository;
    if (repository == null) return;

    final userName = UserDisplayNameFormatter.getUserDisplayName(user);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          interlocutorName: userName,
          interlocutorId: user.id,
          chatRepository: repository,
        ),
      ),
    );
  }
}
