import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat.dart';
import '../providers/auth_provider.dart';

/// Страница детального чата с конкретным пользователем
class ChatDetailPage extends StatefulWidget {
  final String interlocutorName;
  final String interlocutorId;
  final ChatRepository chatRepository;

  const ChatDetailPage({
    super.key,
    required this.interlocutorName,
    required this.interlocutorId,
    required this.chatRepository,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  
  Chat? _chat;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Message? _replyToMessage; // Сообщение, на которое отвечаем
  String? _currentUserId;
  bool _isWebSocketConnected = false;
  bool _useWebSocket = true; // Флаг для использования WebSocket

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Получаем текущего пользователя
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _currentUserId = authProvider.user?.id;

    if (_currentUserId == null) {
      setState(() {
        _error = 'Пользователь не авторизован';
        _isLoading = false;
      });
      return;
    }

    // Получаем или создаем чат
    final chatResult = await widget.chatRepository.getOrCreateChatWithUser(
      widget.interlocutorId,
      currentUserId: _currentUserId,
      currentUserName: authProvider.user?.username ?? '',
    );

    chatResult.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (chat) async {
        setState(() {
          _chat = chat;
        });

        // Загружаем сообщения
        await _loadMessages(chat.id);

        // Подключаемся к WebSocket после загрузки сообщений
        if (_useWebSocket) {
          await _connectWebSocket(chat.id);
        }
      },
    );
  }

  Future<void> _loadMessages(String chatId) async {
    final messagesResult = await widget.chatRepository.getChatMessages(chatId);

    messagesResult.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
      },
      (messages) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });

        // Прокручиваем к последнему сообщению
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients && _messages.isNotEmpty) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      },
    );
  }

  /// Подключиться к WebSocket
  Future<void> _connectWebSocket(String chatId) async {
    final result = await widget.chatRepository.connectWebSocket(
      chatId,
      onNewMessage: (message) {
        // Добавляем новое сообщение от другого пользователя
        if (mounted) {
          setState(() {
            // Проверяем, нет ли уже такого сообщения (избегаем дубликатов)
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
            }
          });

          // Прокручиваем к последнему сообщению
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      onMessageSent: (message) {
        // Подтверждение отправки нашего сообщения
        if (mounted) {
          setState(() {
            // Заменяем временное сообщение на подтвержденное
            final index = _messages.indexWhere((m) => m.id == message.id);
            if (index != -1) {
              _messages[index] = message;
            } else {
              // Если сообщения еще нет, добавляем
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
              }
            }
            _isSending = false;
          });

          // Прокручиваем к последнему сообщению
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      onConnected: () {
        if (mounted) {
          setState(() {
            _isWebSocketConnected = true;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          print('⚠️ WebSocket ошибка: $error');
          // Если WebSocket не работает, переключаемся на POST
          if (!_isWebSocketConnected) {
            setState(() {
              _useWebSocket = false;
            });
          }
        }
      },
      onDisconnected: () {
        if (mounted) {
          setState(() {
            _isWebSocketConnected = false;
          });
        }
      },
    );

    result.fold(
      (failure) {
        print('⚠️ Не удалось подключиться к WebSocket: ${failure.message}');
        // Переключаемся на POST, если WebSocket не работает
        if (mounted) {
          setState(() {
            _useWebSocket = false;
          });
        }
      },
      (_) {
        // Успешное подключение
      },
    );
  }

  @override
  void dispose() {
    // Отключаемся от WebSocket при закрытии страницы
    if (_chat != null && _isWebSocketConnected) {
      widget.chatRepository.disconnectWebSocket();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chat == null || _isSending) return;

    setState(() {
      _isSending = true;
    });

    final replyToMessageId = _replyToMessage?.id;

    // Пытаемся отправить через WebSocket, если подключен
    if (_useWebSocket && _isWebSocketConnected) {
      final wsResult = await widget.chatRepository.sendMessageViaWebSocket(
        text: text,
        replyToMessageId: replyToMessageId,
      );

      wsResult.fold(
        (failure) {
          // Если WebSocket не сработал, пробуем через POST
          print('⚠️ Ошибка отправки через WebSocket: ${failure.message}, пробуем POST');
          _sendMessageViaPost(text, replyToMessageId);
        },
        (_) {
          // Сообщение отправлено через WebSocket, очищаем поле ввода
          // Ответ придет через onMessageSent callback
          setState(() {
            _messageController.clear();
            _replyToMessage = null;
            // _isSending будет установлен в false в onMessageSent
          });
        },
      );
    } else {
      // Используем POST запрос
      _sendMessageViaPost(text, replyToMessageId);
    }
  }

  /// Отправить сообщение через POST (fallback)
  Future<void> _sendMessageViaPost(String text, String? replyToMessageId) async {
    final result = await widget.chatRepository.sendMessage(
      _chat!.id,
      text,
      replyToMessageId: replyToMessageId,
    );

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      },
      (message) {
        setState(() {
          _messages.add(message);
          _messageController.clear();
          _replyToMessage = null;
          _isSending = false;
        });

        // Прокручиваем к последнему сообщению
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      },
    );
  }

  void _selectReplyMessage(Message message) {
    setState(() {
      _replyToMessage = message;
    });
    // Фокусируемся на поле ввода
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _showMessageContextMenu(BuildContext context, Message message) {
    final isMyMessage = message.sender.id == _currentUserId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Индикатор вверху (как в Telegram)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                // Показываем превью сообщения
                if (!isMyMessage)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          child: Text(
                            message.sender.name.isNotEmpty
                                ? message.sender.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.sender.name.isNotEmpty
                                    ? message.sender.name
                                    : 'Пользователь',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                // Список действий
                ListTile(
                  leading: Icon(
                    Icons.reply,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text('Ответить'),
                  onTap: () {
                    Navigator.pop(context);
                    _selectReplyMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Копировать'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.text));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Сообщение скопировано'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                // Можно добавить другие действия в будущем:
                // if (isMyMessage)
                //   ListTile(
                //     leading: const Icon(Icons.delete, color: Colors.red),
                //     title: const Text('Удалить', style: TextStyle(color: Colors.red)),
                //     onTap: () {
                //       // Удаление сообщения
                //       Navigator.pop(context);
                //     },
                // ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                widget.interlocutorName.isNotEmpty
                    ? widget.interlocutorName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.interlocutorName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Показываем сообщение о реплае, если выбрано
          if (_replyToMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.reply, color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyToMessage!.sender.id == _currentUserId
                              ? 'Вы'
                              : _replyToMessage!.sender.name.isNotEmpty
                                  ? _replyToMessage!.sender.name
                                  : 'Пользователь',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _replyToMessage!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReply,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),

          // Список сообщений
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
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
                              onPressed: _loadChat,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              'Пока нет сообщений\nНачните переписку!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMyMessage = message.sender.id == _currentUserId;
                              final showAvatar = index == 0 ||
                                  _messages[index - 1].sender.id != message.sender.id;

                              return GestureDetector(
                                onLongPress: () => _showMessageContextMenu(context, message),
                                child: _buildMessageBubble(
                                  message,
                                  isMyMessage,
                                  showAvatar,
                                ),
                              );
                            },
                          ),
          ),

          // Поле ввода сообщения
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Введите сообщение...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                            padding: const EdgeInsets.all(12),
                            constraints: const BoxConstraints(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    bool isMyMessage,
    bool showAvatar,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
              child: Text(
                message.sender.name.isNotEmpty
                    ? message.sender.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (!isMyMessage) ...[
            const SizedBox(width: 40), // Отступ вместо аватара
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMyMessage ? 18 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Показываем информацию о задаче, если сообщение связано с задачей
                  if (message.isTaskComment && message.task != null) ...[
                    GestureDetector(
                      onTap: () {
                        // Переход на страницу задачи
                        if (message.taskId != null) {
                          Navigator.of(context).pushNamed(
                            '/tasks/detail',
                            arguments: message.taskId,
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isMyMessage
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 16,
                              color: isMyMessage
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                message.task!.title,
                                style: TextStyle(
                                  color: isMyMessage
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: isMyMessage
                                  ? Colors.white70
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Показываем реплай, если есть
                  if (message.replyToMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMyMessage
                            ? Colors.white.withOpacity(0.15)
                            : Colors.grey[400],
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: isMyMessage
                                ? Colors.white.withOpacity(0.5)
                                : Colors.grey[600]!,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.reply,
                                size: 14,
                                color: isMyMessage
                                    ? Colors.white70
                                    : Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.replyToMessage!.isTaskComment
                                    ? 'Ответ на комментарий к задаче'
                                    : 'Ответ на сообщение',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isMyMessage
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.replyToMessage!.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isMyMessage
                                  ? Colors.white70
                                  : Colors.black87,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          // Показываем задачу в реплае, если есть
                          if (message.replyToMessage!.task != null) ...[
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {
                                // Переход на страницу задачи из реплая
                                if (message.replyToMessage!.taskId != null) {
                                  Navigator.of(context).pushNamed(
                                    '/tasks/detail',
                                    arguments: message.replyToMessage!.taskId,
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 12,
                                    color: isMyMessage
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      message.replyToMessage!.task!.title,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isMyMessage
                                            ? Colors.white60
                                            : Colors.black54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 10,
                                    color: isMyMessage
                                        ? Colors.white.withOpacity(0.5)
                                        : Colors.black38,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isMyMessage ? Colors.white70 : Colors.black54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Сегодня - показываем только время
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // Вчера
      return 'Вчера ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      // В течение недели
      final weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return '${weekdays[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Более недели назад
      return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

