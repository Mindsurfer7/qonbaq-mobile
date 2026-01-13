import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import '../../domain/entities/approval.dart';
import '../../domain/entities/approval_decision.dart';
import '../../domain/entities/approval_template.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/get_approval_by_id.dart';
import '../../domain/usecases/decide_approval.dart';
import '../../domain/usecases/create_approval_comment.dart';
import '../../domain/usecases/delete_approval_comment.dart';
import '../../domain/usecases/update_approval.dart';
import '../../core/error/failures.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_detail_page.dart';
import '../widgets/dynamic_block_form.dart';
import '../widgets/comment_section.dart';
import '../widgets/comment_item.dart';
import 'package:dartz/dartz.dart' hide State;

/// Страница детального согласования
class ApprovalDetailPage extends StatefulWidget {
  final String approvalId;

  const ApprovalDetailPage({super.key, required this.approvalId});

  @override
  State<ApprovalDetailPage> createState() => _ApprovalDetailPageState();
}

class _ApprovalDetailPageState extends State<ApprovalDetailPage> {
  Approval? _approval;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  bool _isDeciding = false;

  @override
  void initState() {
    super.initState();
    _loadApproval();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadApproval() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final getApprovalUseCase = Provider.of<GetApprovalById>(
      context,
      listen: false,
    );
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
        // Логи для отладки
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.user;
        final currentUserId = currentUser?.id;
        final creatorId = approval.createdBy;
        final isMatch = currentUserId == creatorId;

        print('=== ЛОГИ СОГЛАСОВАНИЯ ===');
        print('ID текущего пользователя: $currentUserId');
        print('ID создателя согласования: $creatorId');
        print('Совпадают ли ID: $isMatch');
        print('Название согласования: ${approval.title}');
        print('Описание согласования: ${approval.description}');
        print('Описание is null: ${approval.description == null}');
        print('Описание isEmpty: ${approval.description?.isEmpty ?? true}');
        print('Статус согласования: ${approval.status}');
        if (approval.creator != null) {
          print('Информация о создателе:');
          print('  - ID: ${approval.creator!.id}');
          print('  - Email: ${approval.creator!.email}');
          print(
            '  - Имя: ${approval.creator!.firstName} ${approval.creator!.lastName}',
          );
        }
        print('========================');

        setState(() {
          _isLoading = false;
          _approval = approval;
        });
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

  Future<void> _decideApproval(ApprovalDecisionType decision) async {
    if (_approval == null) return;

    final comment = await showDialog<String>(
      context: context,
      builder: (context) => _DecisionDialog(decision: decision),
    );

    if (comment == null &&
        (decision == ApprovalDecisionType.rejected ||
            decision == ApprovalDecisionType.requestChanges)) {
      // Для отклонения и запроса изменений комментарий обязателен
      return;
    }

    setState(() {
      _isDeciding = true;
    });

    final decideApprovalUseCase = Provider.of<DecideApproval>(
      context,
      listen: false,
    );
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
              content: Text(
                decision.decision == ApprovalDecisionType.approved
                    ? 'Согласование одобрено'
                    : decision.decision == ApprovalDecisionType.rejected
                    ? 'Согласование отклонено'
                    : 'Запрошены изменения',
              ),
              backgroundColor:
                  decision.decision == ApprovalDecisionType.approved
                      ? Colors.green
                      : decision.decision == ApprovalDecisionType.rejected
                      ? Colors.red
                      : Colors.orange,
            ),
          );
        }
      },
    );
  }

  Future<void> _editApproval() async {
    if (_approval == null || !_canEdit()) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _EditApprovalDialog(approval: _approval!),
    );

    if (result == true && mounted) {
      // Перезагружаем согласование после редактирования
      _loadApproval();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Согласование успешно обновлено'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final currentUser = authProvider.user;
    if (currentUser == null) return false;

    // Если согласование уже не в статусе pending, нельзя одобрить
    if (_approval!.status != ApprovalStatus.pending) return false;

    // Проверяем привилегированные права (уполномоченный или гендиректор)
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness != null) {
      final permission = currentUser.getPermissionsForBusiness(
        selectedBusiness.id,
      );
      if (permission != null &&
          (permission.isAuthorizedApprover || permission.isGeneralDirector)) {
        // Привилегированные пользователи могут одобрять в любом случае
        return true;
      }
    }

    // Проверяем currentApprover - если текущий пользователь является текущим одобряющим
    if (_approval!.currentApprover != null &&
        _approval!.currentApprover!.id == currentUser.id) {
      return true;
    }

    // Проверяем, есть ли пользователь в списке тех, кто может одобрить
    if (_approval!.approvers != null && _approval!.approvers!.isNotEmpty) {
      return _approval!.approvers!.any(
        (approver) =>
            approver.userId == currentUser.id &&
            approver.approvalId == _approval!.id,
      );
    }

    // Если список approvers пуст или null, возможно все могут одобрить
    // Или это может быть ошибка данных - в этом случае не показываем кнопки
    return false;
  }

  bool _hasAlreadyDecided() {
    if (_approval == null) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return false;

    // Проверяем, есть ли уже решение от текущего пользователя
    if (_approval!.decisions != null && _approval!.decisions!.isNotEmpty) {
      return _approval!.decisions!.any(
        (decision) => decision.userId == currentUser.id,
      );
    }

    return false;
  }

  /// Проверяет, является ли текущий пользователь создателем согласования
  bool _isCreator() {
    if (_approval == null) return false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    if (currentUser == null) return false;

    return _approval!.createdBy == currentUser.id;
  }

  /// Проверяет, можно ли редактировать согласование
  bool _canEdit() {
    if (_approval == null) return false;
    if (!_isCreator()) return false;

    // Нельзя редактировать, если статус: APPROVED, IN_EXECUTION, COMPLETED
    if (_approval!.status == ApprovalStatus.approved ||
        _approval!.status == ApprovalStatus.inExecution ||
        _approval!.status == ApprovalStatus.completed) {
      return false;
    }

    // Нельзя редактировать, если согласование находится у гендиректора или уполномоченного
    // Проверяем, есть ли currentApprover - если есть, значит согласование находится на согласовании
    // и нужно проверить, является ли он гендиректором или уполномоченным
    // Пока что упрощенная проверка: если currentApprover существует, проверяем права текущего пользователя
    // TODO: Нужно проверять права currentApprover, а не текущего пользователя
    // Для этого нужно получать информацию о правах currentApprover через API
    if (_approval!.currentApprover != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final currentUser = authProvider.user;
      final selectedBusiness = profileProvider.selectedBusiness;

      if (currentUser != null && selectedBusiness != null) {
        final permission = currentUser.getPermissionsForBusiness(
          selectedBusiness.id,
        );
        // Если текущий пользователь - гендиректор или уполномоченный,
        // и согласование находится у него, то нельзя редактировать
        if (permission != null &&
            (permission.isAuthorizedApprover || permission.isGeneralDirector) &&
            _approval!.currentApprover!.id == currentUser.id) {
          return false;
        }
      }
    }

    return true;
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
          if (_approval != null && _canEdit())
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editApproval,
              tooltip: 'Редактировать',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApproval,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
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
                  ),
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
                                  _approval!.description != null &&
                                          _approval!.description!.isNotEmpty
                                      ? _approval!.description!
                                      : 'Описание отсутствует',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        _approval!.description != null &&
                                                _approval!
                                                    .description!
                                                    .isNotEmpty
                                            ? null
                                            : Colors.grey,
                                    fontStyle:
                                        _approval!.description != null &&
                                                _approval!
                                                    .description!
                                                    .isNotEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),

                            // Инициатор
                            if (_approval!.initiator != null)
                              _buildInitiatorRow(),

                            // Создатель (если отличается от инициатора)
                            if (_approval!.creator != null &&
                                _approval!.initiator?.id !=
                                    _approval!.creator?.id)
                              _buildCreatorRow(),

                            // Текущий департамент
                            if (_approval!.currentDepartment != null)
                              _buildCurrentDepartmentRow(),

                            // Текущий согласователь
                            if (_approval!.currentApprover != null)
                              _buildCurrentApproverRow(),

                            // Выбранный исполнитель
                            if (_approval!.selectedExecutor != null)
                              _buildSelectedExecutorRow(),

                            // Потенциальные исполнители (показываем только если согласование еще не в исполнении)
                            if (_approval!.potentialExecutors != null &&
                                _approval!.potentialExecutors!.isNotEmpty &&
                                _approval!.status !=
                                    ApprovalStatus.inExecution &&
                                _approval!.status != ApprovalStatus.completed)
                              _buildPotentialExecutorsRow(),

                            // Сумма
                            if (_approval!.amount != null)
                              _buildInfoRow(
                                'Сумма',
                                '${_approval!.amount!.toStringAsFixed(2)} ₸',
                                Icons.attach_money,
                              ),

                            // Payment due date
                            _buildInfoRow(
                              'Срок оплаты',
                              _formatDateTime(_approval!.paymentDueDate),
                              Icons.event,
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
                                  ...(_approval!.decisions!.map(
                                    (decision) => _buildDecisionCard(decision),
                                  )),
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
                                  ...(_approval!.attachments!.map(
                                    (att) => ListTile(
                                      leading: const Icon(Icons.attach_file),
                                      title: Text(att.fileName ?? 'Без имени'),
                                      subtitle: Text(att.fileType ?? ''),
                                    ),
                                  )),
                                  const SizedBox(height: 16),
                                ],
                              ),

                            // Кнопки действий (если можно одобрить)
                            if (_approval!.status ==
                                ApprovalStatus.pending) ...[
                              const Divider(),
                              const SizedBox(height: 16),
                              _canApprove() && !_hasAlreadyDecided()
                                  ? Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isDeciding
                                                  ? null
                                                  : () => _decideApproval(
                                                    ApprovalDecisionType
                                                        .rejected,
                                                  ),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Отклонить'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Кнопка "На доработку" скрыта
                                      // Expanded(
                                      //   child: ElevatedButton.icon(
                                      //     onPressed:
                                      //         _isDeciding
                                      //             ? null
                                      //             : () => _decideApproval(
                                      //               ApprovalDecisionType
                                      //                   .requestChanges,
                                      //             ),
                                      //     icon: const Icon(Icons.edit),
                                      //     label: const Text('На доработку'),
                                      //     style: ElevatedButton.styleFrom(
                                      //       backgroundColor: Colors.orange,
                                      //       foregroundColor: Colors.white,
                                      //       padding: const EdgeInsets.symmetric(
                                      //         vertical: 16,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ),
                                      // const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isDeciding
                                                  ? null
                                                  : () => _decideApproval(
                                                    ApprovalDecisionType
                                                        .approved,
                                                  ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Одобрить'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _hasAlreadyDecided()
                                              ? 'Вы уже приняли решение по этому согласованию'
                                              : 'У вас нет прав для принятия решения',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              const SizedBox(height: 16),
                            ],

                            // Комментарии
                            CommentSection(
                              comments:
                                  _approval!.comments != null
                                      ? CommentItem.fromApprovalComments(
                                        _approval!.comments!,
                                      )
                                      : [],
                              onCreateComment: (text) async {
                                final createCommentUseCase =
                                    Provider.of<CreateApprovalComment>(
                                      context,
                                      listen: false,
                                    );
                                final result = await createCommentUseCase.call(
                                  CreateApprovalCommentParams(
                                    approvalId: _approval!.id,
                                    text: text,
                                  ),
                                );
                                return result.map((_) => null);
                              },
                              onDeleteComment: (commentId) async {
                                final deleteCommentUseCase =
                                    Provider.of<DeleteApprovalComment>(
                                      context,
                                      listen: false,
                                    );
                                return await deleteCommentUseCase.call(
                                  DeleteApprovalCommentParams(
                                    approvalId: _approval!.id,
                                    commentId: commentId,
                                  ),
                                );
                              },
                              onRefresh: _loadApproval,
                              chatRepository: Provider.of<ChatRepository>(
                                context,
                                listen: false,
                              ),
                              showChatButton: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
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
                Text(value, style: TextStyle(fontSize: 16, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitiatorRow() {
    if (_approval!.initiator == null) return const SizedBox.shrink();

    final initiatorName = _getUserDisplayName(_approval!.initiator!);
    final initiatorId = _approval!.initiator!.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Инициатор',
                  style: TextStyle(
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
                        initiatorName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      iconSize: 20,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () =>
                              _openChatWithCreator(initiatorId, initiatorName),
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

  Widget _buildCreatorRow() {
    if (_approval!.creator == null) return const SizedBox.shrink();

    final creatorName = _getUserDisplayName(_approval!.creator!);
    final creatorId = _approval!.creator!.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Создал',
                  style: TextStyle(
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
                        creatorName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      iconSize: 20,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => _openChatWithCreator(creatorId, creatorName),
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

  Widget _buildCurrentDepartmentRow() {
    if (_approval!.currentDepartment == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.business, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Текущий департамент',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _approval!.currentDepartment!.name,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentApproverRow() {
    if (_approval!.currentApprover == null) return const SizedBox.shrink();

    final approverName = _getUserDisplayName(_approval!.currentApprover!);
    final approverId = _approval!.currentApprover!.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.how_to_reg, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Текущий согласователь',
                  style: TextStyle(
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
                        approverName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      iconSize: 20,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => _openChatWithCreator(approverId, approverName),
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

  Widget _buildSelectedExecutorRow() {
    if (_approval!.selectedExecutor == null) return const SizedBox.shrink();

    final executorName = _getUserDisplayName(_approval!.selectedExecutor!);
    final executorId = _approval!.selectedExecutor!.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.assignment_ind, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Исполнитель',
                  style: TextStyle(
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
                        executorName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      iconSize: 20,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed:
                          () => _openChatWithCreator(executorId, executorName),
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

  Widget _buildPotentialExecutorsRow() {
    if (_approval!.potentialExecutors == null ||
        _approval!.potentialExecutors!.isEmpty) {
      return const SizedBox.shrink();
    }

    final executors = _approval!.potentialExecutors!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  executors.length == 1
                      ? 'Потенциальный исполнитель'
                      : 'Потенциальные исполнители',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ...executors.map((executor) {
                  final executorName = _getUserDisplayName(executor);
                  final executorId = executor.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            executorName,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline),
                          iconSize: 20,
                          color: Colors.blue,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed:
                              () => _openChatWithCreator(
                                executorId,
                                executorName,
                              ),
                          tooltip: 'Открыть чат',
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChatWithCreator(String creatorId, String creatorName) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;

    // Не открываем чат с самим собой
    if (currentUserId != null && currentUserId == creatorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя начать чат с самим собой')),
      );
      return;
    }

    final chatRepository = Provider.of<ChatRepository>(context, listen: false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChatDetailPage(
              interlocutorName: creatorName,
              interlocutorId: creatorId,
              chatRepository: chatRepository,
            ),
      ),
    );
  }

  Widget _buildDecisionCard(ApprovalDecision decision) {
    Color cardColor;
    IconData icon;
    Color iconColor;
    String statusText;
    Color statusColor;

    switch (decision.decision) {
      case ApprovalDecisionType.approved:
        cardColor = Colors.green.shade50;
        icon = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Одобрено';
        statusColor = Colors.green;
        break;
      case ApprovalDecisionType.rejected:
        cardColor = Colors.red.shade50;
        icon = Icons.cancel;
        iconColor = Colors.red;
        statusText = 'Отклонено';
        statusColor = Colors.red;
        break;
      case ApprovalDecisionType.requestChanges:
        cardColor = Colors.orange.shade50;
        icon = Icons.edit;
        iconColor = Colors.orange;
        statusText = 'На доработку';
        statusColor = Colors.orange;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cardColor,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          decision.user != null
              ? _getUserDisplayName(decision.user!)
              : 'Пользователь',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decision.department != null) ...[
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    decision.department!.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (decision.comment != null && decision.comment!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(decision.comment!),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDateTime(decision.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Text(
          statusText,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
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
    String title;
    String labelText;
    String buttonText;
    Color buttonColor;
    bool isCommentRequired;

    switch (widget.decision) {
      case ApprovalDecisionType.approved:
        title = 'Одобрить согласование';
        labelText = 'Комментарий (необязательно)';
        buttonText = 'Одобрить';
        buttonColor = Colors.green;
        isCommentRequired = false;
        break;
      case ApprovalDecisionType.rejected:
        title = 'Отклонить согласование';
        labelText = 'Комментарий (обязательно)';
        buttonText = 'Отклонить';
        buttonColor = Colors.red;
        isCommentRequired = true;
        break;
      case ApprovalDecisionType.requestChanges:
        title = 'Запросить изменения';
        labelText = 'Комментарий (обязательно)';
        buttonText = 'Отправить на доработку';
        buttonColor = Colors.orange;
        isCommentRequired = true;
        break;
    }

    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _commentController,
        decoration: InputDecoration(
          labelText: labelText,
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
          onPressed:
              isCommentRequired && _commentController.text.trim().isEmpty
                  ? null
                  : () =>
                      Navigator.of(context).pop(_commentController.text.trim()),
          child: Text(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Диалог редактирования согласования
class _EditApprovalDialog extends StatefulWidget {
  final Approval approval;

  const _EditApprovalDialog({required this.approval});

  @override
  State<_EditApprovalDialog> createState() => _EditApprovalDialogState();
}

class _EditApprovalDialogState extends State<_EditApprovalDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.approval.title;
    _descriptionController.text = widget.approval.description ?? '';

    // Логи для отладки formSchema
    print('=== ЛОГИ ШАБЛОНА В ДИАЛОГЕ РЕДАКТИРОВАНИЯ ===');
    print('Template ID: ${widget.approval.template?.id}');
    print('Template Code: ${widget.approval.template?.code}');
    print('Template Name: ${widget.approval.template?.name}');
    print('FormSchema: ${widget.approval.template?.formSchema}');
    if (widget.approval.template?.formSchema != null) {
      print('FormSchema (pretty):');
      print(_prettyPrintJson(widget.approval.template!.formSchema!));
    }
    print('Initial FormData: ${widget.approval.formData}');
    if (widget.approval.formData != null) {
      print('FormData (pretty):');
      print(_prettyPrintJson(widget.approval.formData!));
    }
    print('============================================');
  }

  String _prettyPrintJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // При редактировании не валидируем форму - PATCH позволяет отправлять только измененные поля
    // if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final formValues = _formKey.currentState!.value;
    final title = _titleController.text.trim();

    // Извлекаем formData из формы так же, как при создании согласования
    final dynamicFormData = <String, dynamic>{};

    formValues.forEach((key, value) {
      // Исключаем системные поля формы
      if (key != 'template' &&
          key != 'title' &&
          key != 'description' &&
          value != null) {
        // Удаляем processName из formData - бэкенд его автоматически удаляет
        if (key == 'processName') {
          return; // Пропускаем processName
        }

        // Преобразуем DateTime в ISO строку для отправки на сервер
        if (value is DateTime) {
          dynamicFormData[key] = value.toIso8601String();
        } else if (value is ApprovalTemplate) {
          // Пропускаем объекты шаблонов
        } else {
          dynamicFormData[key] = value;
        }
      }
    });

    // Если formData пустой, но есть текущий formData, используем его
    Map<String, dynamic>? updatedFormData;
    if (dynamicFormData.isNotEmpty) {
      updatedFormData = dynamicFormData;
    } else if (widget.approval.formData != null) {
      updatedFormData = Map<String, dynamic>.from(widget.approval.formData!);
    }

    final updateApprovalUseCase = Provider.of<UpdateApproval>(
      context,
      listen: false,
    );

    final result = await updateApprovalUseCase.call(
      UpdateApprovalParams(
        approvalId: widget.approval.id,
        title: title.isNotEmpty ? title : null,
        projectId: widget.approval.businessId,
        formData: updatedFormData,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (approval) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          Navigator.of(context).pop(true);
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
    return AlertDialog(
      title: const Text('Редактировать согласование'),
      content: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
              FormBuilderTextField(
                name: 'title',
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                // При редактировании не валидируем обязательные поля
              ),
              const SizedBox(height: 16),
              FormBuilderTextField(
                name: 'description',
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              // Если есть шаблон с formSchema, показываем динамическую форму
              if (widget.approval.template?.formSchema != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    // Логи перед созданием формы
                    print('=== СОЗДАНИЕ DYNAMIC BLOCK FORM ===');
                    print('FormSchema перед передачей в DynamicBlockForm:');
                    print(
                      _prettyPrintJson(widget.approval.template!.formSchema!),
                    );
                    print('InitialValues перед передачей:');
                    if (widget.approval.formData != null) {
                      print(_prettyPrintJson(widget.approval.formData!));
                    } else {
                      print('null');
                    }
                    print('===================================');

                    return DynamicBlockForm(
                      key: ValueKey(
                        widget.approval.template!.code,
                      ), // Уникальный key для пересоздания виджета
                      formSchema: widget.approval.template!.formSchema,
                      initialValues: widget.approval.formData,
                      formKey: _formKey,
                      isEditMode:
                          true, // Режим редактирования - без валидации обязательных полей
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Сохранить'),
        ),
      ],
    );
  }
}
