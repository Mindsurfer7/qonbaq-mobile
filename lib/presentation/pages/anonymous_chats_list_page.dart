import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat.dart';
import '../providers/profile_provider.dart';
import 'chat_detail_page.dart';

/// Страница со списком анонимных чатов бизнеса
class AnonymousChatsListPage extends StatefulWidget {
  final ChatRepository chatRepository;

  const AnonymousChatsListPage({
    super.key,
    required this.chatRepository,
  });

  @override
  State<AnonymousChatsListPage> createState() => _AnonymousChatsListPageState();
}

class _AnonymousChatsListPageState extends State<AnonymousChatsListPage> {
  List<Chat>? _chats;
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _error = 'Компания не выбрана';
        _isLoading = false;
      });
      return;
    }

    final result = await widget.chatRepository.getAnonymousChats(
      selectedBusiness.id,
      page: _page,
      limit: _limit,
    );

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message.isNotEmpty
              ? failure.message
              : 'Ошибка при загрузке чатов';
          _isLoading = false;
        });
      },
      (chats) {
        setState(() {
          if (refresh) {
            _chats = chats;
          } else {
            _chats = [...?(_chats), ...chats];
          }
          _hasMore = chats.length == _limit;
          _isLoading = false;
        });
      },
    );
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _page++;
      _loadChats();
    }
  }

  void _openChat(Chat chat) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          chat: chat,
          chatRepository: widget.chatRepository,
        ),
      ),
    );
  }

  String _getChatTitle(Chat chat) {
    if (chat.business != null) {
      return chat.business!.name;
    }
    if (chat.anonymousHash != null) {
      return 'Клиент ${chat.anonymousHash!.substring(0, 8)}';
    }
    return 'Анонимный чат';
  }

  String _getLastMessagePreview(Chat chat) {
    if (chat.lastMessage == null) {
      return 'Нет сообщений';
    }
    final message = chat.lastMessage!;
    if (message.isAnonymous) {
      return message.text;
    }
    final senderName = message.sender != null && message.sender!.name.isNotEmpty
        ? message.sender!.name
        : 'Сотрудник';
    return '$senderName: ${message.text}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты с клиентами'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading && _chats == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _chats == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadChats(refresh: true),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _chats == null || _chats!.isEmpty
                  ? Center(
                      child: Text(
                        'Нет чатов с клиентами',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadChats(refresh: true),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _chats!.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _chats!.length) {
                            // Кнопка загрузки еще
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : TextButton(
                                        onPressed: _loadMore,
                                        child: const Text('Загрузить еще'),
                                      ),
                              ),
                            );
                          }

                          final chat = _chats![index];
                          return _buildChatCard(chat);
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatCard(Chat chat) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                _getChatTitle(chat),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getLastMessagePreview(chat),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(chat.lastMessage?.createdAt ?? chat.updatedAt),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () => _openChat(chat),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Сегодня ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return '${weekdays[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}
