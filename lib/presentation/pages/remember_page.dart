import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/models/task_model.dart';
import '../providers/inbox_provider.dart';
import '../providers/profile_provider.dart';
import '../../core/services/audio_recording_service.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import '../widgets/create_task_form.dart';

/// Страница "Заметки на ходу" с 4 блоками по категориям
class RememberPage extends StatefulWidget {
  const RememberPage({super.key});

  @override
  State<RememberPage> createState() => _RememberPageState();
}

class _RememberPageState extends State<RememberPage> {
  // Отслеживание перетаскивания
  InboxItem? _draggingItem;
  InboxItemCategory? _draggingFromCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInboxItems();
    });
  }

  void _loadInboxItems() {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final inboxProvider = Provider.of<InboxProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness != null) {
      // Загружаем все элементы (и обработанные, и необработанные)
      inboxProvider.loadInboxItems(businessId: selectedBusiness.id);
    }
  }

  void _showCreateTaskDialog(BuildContext context, InboxItem item) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;
    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    if (selectedBusiness == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Бизнес не выбран')));
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
      builder:
          (context) => Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: Column(
                children: [
                  AppBar(
                    title: const Text('Создать задачу'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: CreateTaskForm(
                      businessId: selectedBusiness.id,
                      userRepository: userRepository,
                      onSubmit: (taskModel) async {
                        final result = await createTaskUseCase.call(
                          CreateTaskParams(task: taskModel, inboxItemId: item.id),
                        );

                        result.fold(
                          (failure) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(failure.message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          (createdTask) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Задача успешно создана'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            // Обновление произойдет автоматически через провайдер
                          },
                        );
                      },
                      onCancel: () => context.pop(),
                      initialTaskData: initialTaskData,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _archiveItem(BuildContext context, InboxItem item) async {
    await _toggleArchiveStatus(context, item, forceArchive: true);
  }

  Future<void> _toggleArchiveStatus(
    BuildContext context,
    InboxItem item, {
    bool? forceArchive,
  }) async {
    final inboxProvider = Provider.of<InboxProvider>(context, listen: false);
    final newArchiveStatus = forceArchive ?? !item.isArchived;

    final success = await inboxProvider.updateItem(
      id: item.id,
      isArchived: newArchiveStatus,
      category: item.category, // Сохраняем категорию
    );

    if (mounted) {
      if (success) {
        // Не показываем сообщение при простом переключении чекбокса
        if (forceArchive == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Элемент обработан')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(inboxProvider.error ?? 'Ошибка обновления'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showItemDetailsDialog(BuildContext context, InboxItem item) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                children: [
                  // AppBar с кнопкой закрытия
                  AppBar(
                    title: const Text('Детали элемента'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  // Контент
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название
                          if (item.title != null && item.title!.isNotEmpty) ...[
                            const Text(
                              'Название',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Категория
                          if (item.category != null) ...[
                            const Text(
                              'Категория',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                item.category!.displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Описание
                          if (item.description != null &&
                              item.description!.isNotEmpty) ...[
                            const Text(
                              'Описание',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description!,
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Статус
                          Row(
                            children: [
                              const Text(
                                'Статус: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      item.isArchived
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        item.isArchived
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.orange.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      item.isArchived
                                          ? Icons.check_circle
                                          : Icons.pending,
                                      size: 16,
                                      color:
                                          item.isArchived
                                              ? Colors.green
                                              : Colors.orange,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.isArchived
                                          ? 'Обработано'
                                          : 'Не обработано',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            item.isArchived
                                                ? Colors.green
                                                : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Даты
                          const Text(
                            'Даты',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Создано: ${_formatDateTime(item.createdAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Обновлено: ${_formatDateTime(item.updatedAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showEditDialog(BuildContext context, InboxItem item) {
    final titleController = TextEditingController(text: item.title ?? '');
    final descriptionController = TextEditingController(
      text: item.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () => context.pop(),
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
                    title:
                        titleController.text.trim().isEmpty
                            ? null
                            : titleController.text.trim(),
                    description:
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                  );
                  if (mounted) {
                    context.pop();
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Успешно обновлено')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            inboxProvider.error ?? 'Ошибка обновления',
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки на ходу'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: () => _handleVoiceRecording(context),
            tooltip: 'Создать голосовым сообщением',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
            tooltip: 'Создать',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInboxItems,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
            },
            tooltip: 'На главную',
          ),
        ],
      ),
      body: Consumer2<InboxProvider, ProfileProvider>(
        builder: (context, inboxProvider, profileProvider, child) {
          final selectedBusiness = profileProvider.selectedBusiness;

          if (selectedBusiness == null) {
            return const Center(child: Text('Выберите компанию'));
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

          final allItems = inboxProvider.items ?? [];
          final unprocessedItems =
              allItems.where((item) => !item.isArchived).toList();
          final processedItems =
              allItems.where((item) => item.isArchived).toList();

          return RefreshIndicator(
            onRefresh: () async {
              _loadInboxItems();
            },
            child: Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Делаем квадратные блоки
                    children: [
                      // Верхний левый - Дела и Задачи (зеленый)
                      _buildQuadrantCard(
                        context,
                        'Дела и Задачи',
                        Colors.green,
                        [
                          InboxItemCategory.workMiscellaneous,
                          InboxItemCategory.personalMiscellaneous,
                        ],
                        unprocessedItems,
                        allItems,
                        _draggingItem,
                        _draggingFromCategory,
                      ),
                      // Верхний правый - Читать и смотреть (синий)
                      _buildQuadrantCard(
                        context,
                        'Читать и смотреть',
                        Colors.blue,
                        [
                          InboxItemCategory.readLater,
                          InboxItemCategory.watchVideoLater,
                        ],
                        unprocessedItems,
                        allItems,
                        _draggingItem,
                        _draggingFromCategory,
                      ),
                      // Нижний левый - Цели и Миссия (серый)
                      _buildQuadrantCard(
                        context,
                        'Цели и Миссия',
                        Colors.grey,
                        [
                          InboxItemCategory.doThisYear,
                          InboxItemCategory.doIn510Years,
                        ],
                        unprocessedItems,
                        allItems,
                        _draggingItem,
                        _draggingFromCategory,
                      ),
                      // Нижний правый - Аналитика (желтый)
                      _buildAnalyticsCard(context, processedItems),
                    ],
                  ),
                ),
                // Большая кнопка микрофона внизу
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FloatingActionButton.large(
                    onPressed: () => _handleVoiceRecording(context),
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.mic, size: 40, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuadrantCard(
    BuildContext context,
    String title,
    Color color,
    List<InboxItemCategory> categories,
    List<InboxItem> unprocessedItems,
    List<InboxItem> allItems,
    InboxItem? draggingItem,
    InboxItemCategory? draggingFromCategory,
  ) {
    // Фильтруем необработанные элементы по категориям
    final categoryItems =
        unprocessedItems
            .where(
              (item) =>
                  item.category != null && categories.contains(item.category),
            )
            .toList();

    // Группируем необработанные по категориям
    final itemsByCategory = <InboxItemCategory, List<InboxItem>>{};
    for (final category in categories) {
      itemsByCategory[category] =
          categoryItems.where((item) => item.category == category).toList();
    }

    // Проверяем наличие обработанных элементов по категориям
    final processedItemsByCategory = <InboxItemCategory, bool>{};
    for (final category in categories) {
      final hasProcessed = allItems.any(
        (item) => item.category == category && item.isArchived,
      );
      processedItemsByCategory[category] = hasProcessed;
    }

    return Card(
      color: color.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Список категорий
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final items = itemsByCategory[category] ?? [];
                final categoryName = category.displayName;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // DragTarget для категории
                      DragTarget<InboxItem>(
                        onAccept: (draggedItem) async {
                          // Сбрасываем состояние перетаскивания
                          setState(() {
                            _draggingItem = null;
                            _draggingFromCategory = null;
                          });

                          // Обновляем category элемента
                          if (draggedItem.category != category) {
                            final inboxProvider = Provider.of<InboxProvider>(
                              context,
                              listen: false,
                            );
                            final profileProvider =
                                Provider.of<ProfileProvider>(
                                  context,
                                  listen: false,
                                );
                            final selectedBusiness =
                                profileProvider.selectedBusiness;

                            final success = await inboxProvider.updateItem(
                              id: draggedItem.id,
                              category: category,
                            );

                            if (mounted) {
                              if (success) {
                                // Перезагружаем данные для синхронизации
                                if (selectedBusiness != null) {
                                  await inboxProvider.loadInboxItems(
                                    businessId: selectedBusiness.id,
                                  );
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Категория обновлена'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      inboxProvider.error ??
                                          'Ошибка обновления категории',
                                    ),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          // Подсвечиваем если:
                          // 1. Элемент перетаскивается (draggingItem != null)
                          // 2. Это не исходная категория (category != draggingFromCategory)
                          // 3. ИЛИ курсор находится над этой областью И это не исходная категория
                          final isDragging = draggingItem != null;
                          final isSourceCategory =
                              draggingFromCategory == category;
                          final isNotSourceCategory =
                              draggingFromCategory != null && !isSourceCategory;
                          final isHovered = candidateData.isNotEmpty;
                          // Подсвечиваем все доступные категории при перетаскивании,
                          // кроме исходной, или если курсор над областью (но не исходной)
                          final shouldHighlight =
                              (isDragging && isNotSourceCategory) ||
                              (isHovered && !isSourceCategory);

                          return Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 35),
                            decoration: BoxDecoration(
                              color:
                                  shouldHighlight
                                      ? color.withOpacity(0.3)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Список элементов категории
                                ...items.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      top: index == 0 ? 4.0 : 0.0,
                                      bottom: 4.0,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: _DraggableInboxItem(
                                        item: item,
                                        onConvertToTask:
                                            () => _showCreateTaskDialog(
                                              context,
                                              item,
                                            ),
                                        onArchive:
                                            () => _archiveItem(context, item),
                                        onEdit:
                                            () =>
                                                _showEditDialog(context, item),
                                        onShowDetails:
                                            () => _showItemDetailsDialog(
                                              context,
                                              item,
                                            ),
                                        onToggleCheck:
                                            (item) => _toggleArchiveStatus(
                                              context,
                                              item,
                                            ),
                                        onDragStart: () {
                                          setState(() {
                                            _draggingItem = item;
                                            _draggingFromCategory =
                                                item.category;
                                          });
                                        },
                                        onDragEnd: () {
                                          setState(() {
                                            _draggingItem = null;
                                            _draggingFromCategory = null;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    List<InboxItem> processedItems,
  ) {
    // Группируем обработанные элементы по категориям
    final itemsByCategory = <InboxItemCategory, List<InboxItem>>{};
    for (final item in processedItems) {
      if (item.category != null) {
        itemsByCategory.putIfAbsent(item.category!, () => []).add(item);
      }
    }

    // Сортируем категории по порядку
    final sortedCategories =
        InboxItemCategory.values
            .where((category) => itemsByCategory.containsKey(category))
            .toList();

    return Card(
      color: Colors.amber.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Аналитика',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          // Подзаголовок
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              'Обработанные',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          // Список обработанных элементов
          Expanded(
            child:
                sortedCategories.isEmpty
                    ? const Center(
                      child: Text(
                        'Нет обработанных элементов',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: sortedCategories.length,
                      itemBuilder: (context, index) {
                        final category = sortedCategories[index];
                        final categoryName = category.displayName;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Бизнес не выбран')));
      return;
    }

    final _formKey = GlobalKey<FormBuilderState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Создать элемент'),
            content: FormBuilder(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormBuilderTextField(
                    name: 'title',
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormBuilderTextField(
                    name: 'description',
                    decoration: const InputDecoration(
                      labelText: 'Описание',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  FormBuilderDropdown<InboxItemCategory>(
                    name: 'category',
                    decoration: InputDecoration(
                      labelText: 'Категория *',
                      border: const OutlineInputBorder(),
                    ),
                    dropdownColor: context.appTheme.backgroundSurface,
                    borderRadius: BorderRadius.circular(
                      context.appTheme.borderRadius,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Категория обязательна',
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return InboxItemCategory.values.map<Widget>((
                        InboxItemCategory category,
                      ) {
                        return Text(category.displayName);
                      }).toList();
                    },
                    items:
                        InboxItemCategory.values
                            .map(
                              (category) =>
                                  createStyledDropdownItem<InboxItemCategory>(
                                    context: context,
                                    value: category,
                                    child: Text(category.displayName),
                                  ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.saveAndValidate() ?? false) {
                    final formData = _formKey.currentState!.value;
                    final inboxProvider = Provider.of<InboxProvider>(
                      context,
                      listen: false,
                    );
                    final success = await inboxProvider.createItem(
                      businessId: selectedBusiness.id,
                      title:
                          (formData['title'] as String?)?.trim().isEmpty ?? true
                              ? null
                              : (formData['title'] as String?)?.trim(),
                      description:
                          (formData['description'] as String?)
                                      ?.trim()
                                      .isEmpty ??
                                  true
                              ? null
                              : (formData['description'] as String?)?.trim(),
                      category: formData['category'] as InboxItemCategory?,
                    );
                    if (mounted) {
                      context.pop();
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Успешно создано')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              inboxProvider.error ?? 'Ошибка создания',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Создать'),
              ),
            ],
          ),
    );
  }

  void _handleVoiceRecording(BuildContext context) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final inboxProvider = Provider.of<InboxProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Бизнес не выбран')));
      return;
    }

    // Показываем диалог записи
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => _VoiceRecordingDialog(
            businessId: selectedBusiness.id,
            onResult: (audioFile, audioBytes) async {
              context.pop();

              // Отправляем на backend
              final success = await inboxProvider.createItemFromVoice(
                audioFile: audioFile,
                audioBytes: audioBytes,
                businessId: selectedBusiness.id,
              );

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Элемент успешно создан')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(inboxProvider.error ?? 'Ошибка создания'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            onError: (error) {
              context.pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
              }
            },
          ),
    );
  }
}

/// Диалог для записи голосового сообщения
class _VoiceRecordingDialog extends StatefulWidget {
  final String businessId;
  final void Function(String? audioFile, List<int>? audioBytes) onResult;
  final void Function(String error) onError;

  const _VoiceRecordingDialog({
    required this.businessId,
    required this.onResult,
    required this.onError,
  });

  @override
  State<_VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<_VoiceRecordingDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecording();
    });
  }

  Future<void> _startRecording() async {
    final audioService = Provider.of<AudioRecordingService>(
      context,
      listen: false,
    );
    try {
      await audioService.startRecording();
    } catch (e) {
      widget.onError('Ошибка начала записи: $e');
    }
  }

  Future<void> _stopAndSend() async {
    final audioService = Provider.of<AudioRecordingService>(
      context,
      listen: false,
    );

    try {
      // Останавливаем запись
      if (audioService.state == RecordingState.recording) {
        await audioService.stopRecording();
      }

      // Получаем путь к файлу или байты
      String? audioFile;
      List<int>? audioBytes;

      if (kIsWeb) {
        // Для веба нужно получить байты из blob URL
        final blobUrl = audioService.currentRecordingPath;
        if (blobUrl == null) {
          widget.onError('Blob URL не найден');
          return;
        }

        try {
          final audioResponse = await http.get(Uri.parse(blobUrl));
          if (audioResponse.statusCode != 200) {
            widget.onError(
              'Ошибка загрузки из Blob: ${audioResponse.statusCode}',
            );
            return;
          }

          audioBytes = audioResponse.bodyBytes;
          if (audioBytes.isEmpty) {
            widget.onError('Запись пустая');
            return;
          }

          // Проверяем размер файла (максимум 25 МБ)
          const maxSizeInBytes = 25 * 1024 * 1024; // 25 МБ
          if (audioBytes.length > maxSizeInBytes) {
            widget.onError('Файл слишком большой. Максимум: 25 МБ');
            return;
          }
        } catch (e) {
          widget.onError('Ошибка получения аудио из Blob: $e');
          return;
        }
      } else {
        audioFile = audioService.currentRecordingPath;
        if (audioFile == null) {
          widget.onError('Путь к записи не найден');
          return;
        }
      }

      // Передаем результат
      widget.onResult(audioFile, audioBytes);
    } catch (e) {
      widget.onError('Ошибка обработки записи: $e');
    }
  }

  void _cancel() {
    final audioService = Provider.of<AudioRecordingService>(
      context,
      listen: false,
    );
    audioService.cancelRecording();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioRecordingService>(
      builder: (context, audioService, child) {
        final minutes = audioService.recordingDuration ~/ 60;
        final seconds = audioService.recordingDuration % 60;
        final timeText =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

        return AlertDialog(
          title: const Text('Запись голосового сообщения'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (audioService.state == RecordingState.recording) ...[
                const Icon(Icons.mic, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Идет запись...'),
              ] else if (audioService.state == RecordingState.recorded) ...[
                const Icon(Icons.check_circle, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Запись завершена'),
              ] else if (audioService.state == RecordingState.loading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Обработка...'),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: _cancel, child: const Text('Отмена')),
            if (audioService.state == RecordingState.recording ||
                audioService.state == RecordingState.recorded)
              ElevatedButton(
                onPressed:
                    audioService.state == RecordingState.loading
                        ? null
                        : _stopAndSend,
                child: const Text('Отправить'),
              ),
          ],
        );
      },
    );
  }
}

/// Draggable виджет для Inbox Item
class _DraggableInboxItem extends StatefulWidget {
  final InboxItem item;
  final VoidCallback onConvertToTask;
  final VoidCallback onArchive;
  final VoidCallback onEdit;
  final VoidCallback onShowDetails;
  final Function(InboxItem) onToggleCheck;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;

  const _DraggableInboxItem({
    required this.item,
    required this.onConvertToTask,
    required this.onArchive,
    required this.onEdit,
    required this.onShowDetails,
    required this.onToggleCheck,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<_DraggableInboxItem> createState() => _DraggableInboxItemState();
}

class _DraggableInboxItemState extends State<_DraggableInboxItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimationController;
  late Animation<double> _checkAnimation;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.easeInOut,
    );
    // Если элемент уже обработан, показываем галочку сразу
    if (widget.item.isArchived) {
      _checkAnimationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(_DraggableInboxItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Анимируем изменение статуса
    if (oldWidget.item.isArchived != widget.item.isArchived) {
      if (widget.item.isArchived) {
        _checkAnimationController.forward();
      } else {
        _checkAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkAnimationController.dispose();
    super.dispose();
  }

  // Для веба используем Draggable, для мобильных - LongPressDraggable
  Widget _buildDraggable() {
    final draggableContent = _buildItemContent();

    if (kIsWeb) {
      // Для веба используем обычный Draggable
      return Draggable<InboxItem>(
        data: widget.item,
        onDragStarted: () {
          widget.onDragStart?.call();
        },
        onDragEnd: (details) {
          widget.onDragEnd?.call();
        },
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.title ?? 'Без названия',
                  style: TextStyle(
                    fontSize: 12,
                    decoration:
                        widget.item.isArchived
                            ? TextDecoration.lineThrough
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: draggableContent),
        child: draggableContent,
      );
    } else {
      // Для мобильных используем LongPressDraggable
      return LongPressDraggable<InboxItem>(
        data: widget.item,
        onDragStarted: () {
          widget.onDragStart?.call();
        },
        onDragEnd: (details) {
          widget.onDragEnd?.call();
        },
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.item.title ?? 'Без названия',
                  style: TextStyle(
                    fontSize: 12,
                    decoration:
                        widget.item.isArchived
                            ? TextDecoration.lineThrough
                            : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: draggableContent),
        child: draggableContent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildDraggable();
  }

  Widget _buildItemContent() {
    final isArchived = widget.item.isArchived;

    return Opacity(
      opacity: isArchived ? 0.65 : 1.0, // 0.65 в диапазоне 0.6-0.7
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Чекбокс или зачеркнутая галочка слева
            GestureDetector(
              onTap: () => widget.onToggleCheck(widget.item),
              child: Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                child:
                    isArchived
                        ? const Icon(
                          Icons.check_circle,
                          size: 20,
                          color: Colors.green,
                        )
                        : Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            // Анимированная галочка
                            ScaleTransition(
                              scale: _checkAnimation,
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
            // Текст элемента
            Expanded(
              child: Text(
                widget.item.title ?? 'Без названия',
                style: TextStyle(
                  fontSize: 12,
                  decoration: isArchived ? TextDecoration.lineThrough : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Троеточие и иконки управления
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Иконки управления (показываются при нажатии на троеточие)
                if (_showControls) ...[
                  IconButton(
                    icon: const Icon(Icons.info_outline, size: 16),
                    onPressed: () {
                      setState(() => _showControls = false);
                      widget.onShowDetails();
                    },
                    tooltip: 'Детали',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.task, size: 16),
                    onPressed: () {
                      setState(() => _showControls = false);
                      widget.onConvertToTask();
                    },
                    tooltip: 'Превратить в задачу',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive, size: 16),
                    onPressed: () {
                      setState(() => _showControls = false);
                      widget.onArchive();
                    },
                    tooltip: 'Обработать',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    onPressed: () {
                      setState(() => _showControls = false);
                      widget.onEdit();
                    },
                    tooltip: 'Редактировать',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
                // Иконка троеточия
                IconButton(
                  icon: Icon(
                    _showControls ? Icons.close : Icons.more_vert,
                    size: 16,
                  ),
                  onPressed: () {
                    setState(() => _showControls = !_showControls);
                  },
                  tooltip: 'Действия',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
