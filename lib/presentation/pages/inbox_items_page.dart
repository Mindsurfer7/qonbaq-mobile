import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../../data/models/task_model.dart';
import '../../data/models/validation_error.dart';
import '../providers/inbox_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/create_task_form.dart';

/// Страница "Не забыть выполнить" (Inbox Items)
class InboxItemsPage extends StatefulWidget {
  const InboxItemsPage({super.key});

  @override
  State<InboxItemsPage> createState() => _InboxItemsPageState();
}

class _InboxItemsPageState extends State<InboxItemsPage> {
  final Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInboxItems();
    });
  }

  void _loadInboxItems() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final inboxProvider = Provider.of<InboxProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness != null) {
      inboxProvider.loadInboxItems(
        businessId: selectedBusiness.id,
      );
    }
  }

  void _toggleExpanded(String itemId) {
    setState(() {
      _expandedItems[itemId] = !(_expandedItems[itemId] ?? false);
    });
  }

  void _showEditDialog(InboxItem item) {
    final titleController = TextEditingController(text: item.title ?? '');
    final descriptionController = TextEditingController(text: item.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final inboxProvider = Provider.of<InboxProvider>(
                context,
                listen: false,
              );
              final success = await inboxProvider.updateItem(
                id: item.id,
                title: titleController.text.trim().isEmpty
                    ? null
                    : titleController.text.trim(),
                description: descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim(),
              );
              if (mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Успешно обновлено')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(inboxProvider.error ?? 'Ошибка обновления'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(InboxItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить?'),
        content: const Text('Вы уверены, что хотите удалить этот элемент?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final inboxProvider = Provider.of<InboxProvider>(
                context,
                listen: false,
              );
              final success = await inboxProvider.deleteItem(item.id);
              if (mounted) {
                Navigator.of(context).pop();
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Успешно удалено')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(inboxProvider.error ?? 'Ошибка удаления'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog(InboxItem item) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бизнес не выбран')),
      );
      return;
    }

    // Предзаполняем форму данными из inbox item
    final initialTaskData = TaskModel(
      id: '',
      businessId: selectedBusiness.id,
      title: item.title ?? 'Без названия',
      description: item.description,
      status: TaskStatus.pending,
      priority: null,
      assignedTo: null,
      assignedBy: null,
      assignmentDate: null,
      deadline: null,
      isImportant: false,
      isRecurring: false,
      hasControlPoint: false,
      dontForget: false,
      voiceNoteUrl: null,
      resultText: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      observerIds: null,
      attachments: null,
      indicators: null,
      recurrence: null,
      business: null,
      assignee: null,
      assigner: null,
      observers: null,
      comments: null,
    );

    showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(
        businessId: selectedBusiness.id,
        userRepository: userRepository,
        createTaskUseCase: createTaskUseCase,
        inboxItemId: item.id,
        initialTaskData: initialTaskData,
        onSuccess: () {
          // После успешного создания задачи inbox item будет заархивирован автоматически
          // Обновляем список
          _loadInboxItems();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Не забыть выполнить'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInboxItems,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: Consumer2<InboxProvider, ProfileProvider>(
        builder: (context, inboxProvider, profileProvider, child) {
          final selectedBusiness = profileProvider.selectedBusiness;

          if (selectedBusiness == null) {
            return const Center(
              child: Text('Выберите компанию'),
            );
          }

          if (inboxProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (inboxProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    inboxProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadInboxItems,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final activeItems = inboxProvider.activeItems;
          final archivedItems = inboxProvider.archivedItems;

          if (activeItems.isEmpty && archivedItems.isEmpty) {
            return const Center(
              child: Text(
                'Нет элементов',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadInboxItems();
            },
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Активные элементы
                if (activeItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Активные',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...activeItems.map((item) => _buildInboxItemCard(
                        context,
                        item,
                        inboxProvider,
                        isArchived: false,
                      )),
                ],

                // Заархивированные элементы
                if (archivedItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Заархивированные',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...archivedItems.map((item) => _buildInboxItemCard(
                        context,
                        item,
                        inboxProvider,
                        isArchived: true,
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInboxItemCard(
    BuildContext context,
    InboxItem item,
    InboxProvider inboxProvider, {
    required bool isArchived,
  }) {
    final isExpanded = _expandedItems[item.id] ?? false;

    return Opacity(
      opacity: isArchived ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.inbox,
                color: isArchived ? Colors.grey : Colors.orange,
              ),
              title: Text(
                item.title ?? 'Без названия',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isArchived
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: item.description != null && item.description!.isNotEmpty
                  ? Text(
                      item.description!,
                      maxLines: isExpanded ? null : 2,
                      overflow: isExpanded ? null : TextOverflow.ellipsis,
                    )
                  : null,
              trailing: IconButton(
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () => _toggleExpanded(item.id),
              ),
              onTap: () => _toggleExpanded(item.id),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.description != null &&
                        item.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          item.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Кнопка редактирования
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditDialog(item),
                          tooltip: 'Редактировать',
                        ),
                        // Кнопка превратить в задачу
                        IconButton(
                          icon: const Icon(Icons.task),
                          onPressed: () => _showCreateTaskDialog(item),
                          tooltip: 'Превратить в задачу',
                        ),
                        // Кнопка удаления
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmDialog(item),
                          tooltip: 'Удалить',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Диалог создания задачи из Inbox Item
class _CreateTaskDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateTask createTaskUseCase;
  final String? inboxItemId;
  final TaskModel? initialTaskData;
  final VoidCallback onSuccess;

  const _CreateTaskDialog({
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
    this.inboxItemId,
    this.initialTaskData,
    required this.onSuccess,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  void _handleError(String? error) {
    setState(() {
      _error = error;
    });
  }

  void _handleSubmit(Task task) async {
    setState(() {
      _error = null;
      _validationErrors = null;
    });

    final result = await widget.createTaskUseCase.call(
      CreateTaskParams(
        task: task,
        inboxItemId: widget.inboxItemId,
      ),
    );

    result.fold(
      (failure) {
        if (failure is ValidationFailure) {
          setState(() {
            _validationErrors = failure.errors;
            _error = failure.message;
          });
        } else {
          setState(() {
            _error = failure.message;
          });
        }
      },
      (createdTask) {
        Navigator.of(context).pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача успешно создана')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: const Text('Создать задачу'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: CreateTaskForm(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                onSubmit: _handleSubmit,
                onCancel: () => Navigator.of(context).pop(),
                error: _error,
                validationErrors: _validationErrors,
                onError: _handleError,
                initialTaskData: widget.initialTaskData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

