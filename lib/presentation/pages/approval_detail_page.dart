import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_comment.dart';
import '../../domain/entities/approval_decision.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_approval_by_id.dart';
import '../../domain/usecases/decide_approval.dart';
import '../../domain/usecases/create_approval_comment.dart';
import '../../domain/usecases/delete_approval_comment.dart';
import '../../core/error/failures.dart';
import '../providers/auth_provider.dart';

/// Страница детального согласования
class ApprovalDetailPage extends StatefulWidget {
  final String approvalId;

  const ApprovalDetailPage({
    super.key,
    required this.approvalId,
  });

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  Approval? _approval;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingComment = false;
  bool _isDeciding = false;

  @override
  void initState() {
    super.initState();
    _loadApproval();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApproval() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getApprovalUseCase = Provider.of<GetApprovalById>(context, listen: false);
    final result = await getApprovalUseCase.call(widget.approvalId);

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке согласования'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (approval) {
        setState(() {
          _isLoading = false;
          _approval = approval;
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty || _approval == null) return;

    setState(() {
      _isSendingComment = true;
    });

    final createCommentUseCase = Provider.of<CreateApprovalComment>(context, listen: false);
    final result = await createCommentUseCase.call(
      CreateApprovalCommentParams(
        approvalId: _approval!.id,
        text: _commentController.text.trim(),
      ),
    );

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
      (comment) {
        _commentController.clear();
        setState(() {
          _isSendingComment = false;
        });
        // Перезагружаем согласование, чтобы получить обновленный список комментариев
        _loadApproval();
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

  Future<void> _decideApproval(ApprovalDecisionType decision) async {
    if (_approval == null) return;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _DecisionDialog(decision: decision),
    );

    if (comment == null && decision == ApprovalDecisionType.rejected) {
      // Для отклонения комментарий обязателен
      return;
    }

    setState(() {
      _isDeciding = true;
    });

    final decideApprovalUseCase = Provider.of<DecideApproval>(context, listen: false);
    final result = await decideApprovalUseCase.call(
      DecideApprovalParams(
        approvalId: _approval!.id,
        decision: decision,
        comment: comment,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isDeciding = false;
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
      (decision) {
        setState(() {
          _isDeciding = false;
        });
        // Перезагружаем согласование
        _loadApproval();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(decision.decision == ApprovalDecisionType.approved
                  ? 'Согласование одобрено'
                  : 'Согласование отклонено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteComment(ApprovalComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить комментарий?'),
        content: const Text('Вы уверены, что хотите удалить этот комментарий?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || _approval == null) return;

    final deleteCommentUseCase = Provider.of<DeleteApprovalComment>(context, listen: false);
    final result = await deleteCommentUseCase.call(
      DeleteApprovalCommentParams(
        approvalId: _approval!.id,
        commentId: comment.id,
      ),
    );

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
        // Перезагружаем согласование
        _loadApproval();
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

  String _getStatusText(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return 'Черновик';
      case ApprovalStatus.pending:
        return 'На согласовании';
      case ApprovalStatus.approved:
        return 'Утверждено';
      case ApprovalStatus.rejected:
        return 'Отклонено';
      case ApprovalStatus.inExecution:
        return 'В исполнении';
      case ApprovalStatus.completed:
        return 'Завершено';
      case ApprovalStatus.cancelled:
        return 'Отменено';
    }
  }

  Color _getStatusColor(ApprovalStatus status) {
    switch (status) {
      case ApprovalStatus.draft:
        return Colors.grey;
      case ApprovalStatus.pending:
        return Colors.orange;
      case ApprovalStatus.approved:
        return Colors.green;
      case ApprovalStatus.rejected:
        return Colors.red;
      case ApprovalStatus.inExecution:
        return Colors.blue;
      case ApprovalStatus.completed:
        return Colors.teal;
      case ApprovalStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final approvalDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (approvalDate == today) {
      return 'Сегодня ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.add(const Duration(days: 1))) {
      return 'Завтра ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (approvalDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _getUserDisplayName(ProfileUser user) {
    final parts = <String>[];
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      parts.add(user.firstName!);
    }
    if (user.patronymic != null && user.patronymic!.isNotEmpty) {
      parts.add(user.patronymic!);
    }
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  bool _canApprove() {
    if (_approval == null) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return false;

    // Проверяем, есть ли пользователь в списке тех, кто может одобрить
    if (_approval!.approvers != null) {
      return _approval!.approvers!.any((approver) => approver.userId == currentUser.id);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_approval?.title ?? 'Согласование'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApproval,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApproval,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _approval == null
                  ? const Center(child: Text('Согласование не найдено'))
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadApproval,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок и статус
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _approval!.title,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(_approval!.status),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          _getStatusText(_approval!.status),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Описание
                                  if (_approval!.description != null &&
                                      _approval!.description!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Описание',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _approval!.description!,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Создатель
                                  if (_approval!.creator != null)
                                    _buildInfoRow(
                                      'Создал',
                                      _getUserDisplayName(_approval!.creator!),
                                      Icons.person,
                                    ),

                                  // Дата создания
                                  _buildInfoRow(
                                    'Дата создания',
                                    _formatDateTime(_approval!.createdAt),
                                    Icons.calendar_today,
                                  ),

                                  // Решения
                                  if (_approval!.decisions != null &&
                                      _approval!.decisions!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Решения',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_approval!.decisions!.map((decision) =>
                                            _buildDecisionCard(decision))),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Вложения
                                  if (_approval!.attachments != null &&
                                      _approval!.attachments!.isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Вложения',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_approval!.attachments!.map((att) =>
                                            ListTile(
                                              leading: const Icon(Icons.attach_file),
                                              title: Text(att.fileName ?? 'Без имени'),
                                              subtitle: Text(att.fileType ?? ''),
                                            ))),
                                        const SizedBox(height: 16),
                                      ],
                                    ),

                                  // Комментарии
                                  const Divider(),
                                  const Text(
                                    'Комментарии',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  if (_approval!.comments == null ||
                                      _approval!.comments!.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'Комментариев пока нет',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  else
                                    ...(_approval!.comments!.map((comment) =>
                                        _buildCommentCard(comment))),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Кнопки действий (если можно одобрить)
                        if (_canApprove() &&
                            _approval!.status == ApprovalStatus.pending)
                          Container(
                            padding: const EdgeInsets.all(16),
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
                                  child: ElevatedButton.icon(
                                    onPressed: _isDeciding
                                        ? null
                                        : () => _decideApproval(
                                            ApprovalDecisionType.rejected),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Отклонить'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isDeciding
                                        ? null
                                        : () => _decideApproval(
                                            ApprovalDecisionType.approved),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Одобрить'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

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
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(ApprovalDecision decision) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: decision.decision == ApprovalDecisionType.approved
          ? Colors.green.shade50
          : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          decision.decision == ApprovalDecisionType.approved
              ? Icons.check_circle
              : Icons.cancel,
          color: decision.decision == ApprovalDecisionType.approved
              ? Colors.green
              : Colors.red,
        ),
        title: Text(
          decision.user != null
              ? _getUserDisplayName(decision.user!)
              : 'Пользователь',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decision.comment != null && decision.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(decision.comment!),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDateTime(decision.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: Text(
          decision.decision == ApprovalDecisionType.approved
              ? 'Одобрено'
              : 'Отклонено',
          style: TextStyle(
            color: decision.decision == ApprovalDecisionType.approved
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentCard(ApprovalComment comment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          child: Text(
            comment.user != null
                ? _getUserDisplayName(comment.user!)
                    .substring(0, 1)
                    .toUpperCase()
                : '?',
          ),
        ),
        title: Text(
          comment.user != null
              ? _getUserDisplayName(comment.user!)
              : 'Пользователь',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(comment.text),
            const SizedBox(height: 8),
            Text(
              _formatDateTime(comment.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteComment(comment),
          tooltip: 'Удалить',
        ),
      ),
    );
  }
}

/// Диалог для ввода комментария при принятии решения
class _DecisionDialog extends StatefulWidget {
  final ApprovalDecisionType decision;

  const _DecisionDialog({required this.decision});

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.decision == ApprovalDecisionType.approved
          ? 'Одобрить согласование'
          : 'Отклонить согласование'),
      content: TextField(
        controller: _commentController,
        decoration: InputDecoration(
          labelText: widget.decision == ApprovalDecisionType.approved
              ? 'Комментарий (необязательно)'
              : 'Комментарий (обязательно)',
          hintText: 'Введите комментарий...',
          border: const OutlineInputBorder(),
        ),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: widget.decision == ApprovalDecisionType.rejected &&
                  _commentController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_commentController.text.trim()),
          child: Text(widget.decision == ApprovalDecisionType.approved
              ? 'Одобрить'
              : 'Отклонить'),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.decision == ApprovalDecisionType.approved
                ? Colors.green
                : Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

