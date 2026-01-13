import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart' hide State;
import '../../core/error/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import 'comment_item.dart';
import 'comment_card.dart';

/// Универсальный виджет для отображения и управления комментариями
/// Работает как с Task, так и с Approval комментариями
class CommentSection extends StatefulWidget {
  /// Список комментариев для отображения
  final List<CommentItem> comments;

  /// Callback для создания нового комментария
  /// Принимает текст комментария, возвращает Either<Failure, void>
  final Future<Either<Failure, void>> Function(String text) onCreateComment;

  /// Callback для удаления комментария
  /// Принимает ID комментария, возвращает Either<Failure, void>
  final Future<Either<Failure, void>> Function(String commentId) onDeleteComment;

  /// Callback для обновления списка комментариев после операций
  final VoidCallback? onRefresh;

  /// Репозиторий чата для открытия чата с автором комментария (опционально)
  final ChatRepository? chatRepository;

  /// Показывать ли кнопку открытия чата
  final bool showChatButton;

  /// Сообщение, когда комментариев нет
  final String emptyMessage;

  const CommentSection({
    super.key,
    required this.comments,
    required this.onCreateComment,
    required this.onDeleteComment,
    this.onRefresh,
    this.chatRepository,
    this.showChatButton = true,
    this.emptyMessage = 'Комментариев пока нет',
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSendingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isSendingComment = true;
    });

    final result = await widget.onCreateComment(_commentController.text.trim());

    result.fold(
      (failure) {
        setState(() {
          _isSendingComment = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        _commentController.clear();
        setState(() {
          _isSendingComment = false;
        });
        // Обновляем список комментариев
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Комментарий добавлен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        content: const Text(
          'Вы уверены, что хотите удалить этот комментарий?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await widget.onDeleteComment(comment.id);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(failure)),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        // Обновляем список комментариев
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Комментарий удален'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ForbiddenFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text(
          'Комментарии',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (widget.comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.emptyMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          ...widget.comments.map(
            (comment) => CommentCard(
              comment: comment,
              onDelete: () => _deleteComment(comment),
              chatRepository: widget.chatRepository,
              showChatButton: widget.showChatButton,
            ),
          ),
        const SizedBox(height: 16),
        // Поле ввода комментария
        Container(
          padding: const EdgeInsets.all(8),
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Добавить комментарий...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isSendingComment
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send),
                onPressed: _isSendingComment ? null : _sendComment,
                tooltip: 'Отправить',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
