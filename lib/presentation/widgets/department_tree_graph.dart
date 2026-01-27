import 'package:flutter/material.dart';
import '../../domain/entities/department.dart';

/// Виджет для отображения графа организационной структуры
class DepartmentTreeGraph extends StatefulWidget {
  final List<Department> departments;
  final String? businessName; // Название бизнеса для отображения вверху
  final Function(String departmentId)? onDepartmentTap;

  const DepartmentTreeGraph({
    super.key,
    required this.departments,
    this.businessName,
    this.onDepartmentTap,
  });

  @override
  State<DepartmentTreeGraph> createState() => _DepartmentTreeGraphState();
}

class _DepartmentTreeGraphState extends State<DepartmentTreeGraph> {
  final Set<String> _expandedNodes = {}; // Отслеживаем раскрытые узлы

  @override
  Widget build(BuildContext context) {
    if (widget.departments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Нет подразделений для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Строим дерево
    final tree = _buildTree(widget.departments);
    if (tree.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Не удалось построить дерево',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Определяем, мобильный ли это экран
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return _buildMobileAccordionView(tree);
    } else {
      return _buildDesktopGraphView(tree);
    }
  }

  /// Строит мобильный вид с аккордеоном
  Widget _buildMobileAccordionView(Map<String, List<Department>> tree) {
    final rootDepartments = tree['root'] ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Бизнес вверху (если есть)
          if (widget.businessName != null) ...[
            _buildBusinessCard(widget.businessName!),
            const SizedBox(height: 8),
          ],
          // Дерево подразделений
          ...rootDepartments.map((dept) => 
            _buildAccordionNode(dept, tree, 0)
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Строит десктопный вид с графом (текущая реализация)
  Widget _buildDesktopGraphView(Map<String, List<Department>> tree) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Бизнес вверху
            if (widget.businessName != null) ...[
              _buildBusinessNode(widget.businessName!),
              const SizedBox(height: 24),
              // Линия от бизнеса к подразделениям
              Container(
                height: 20,
                width: 2,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
            ],
            // Дерево подразделений
            _buildTreeWidget(tree, 0),
          ],
        ),
      ),
    );
  }

  /// Строит карточку бизнеса для мобильного вида
  Widget _buildBusinessCard(String businessName) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.business, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                businessName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Строит узел аккордеона с визуальными линиями иерархии
  Widget _buildAccordionNode(
    Department department,
    Map<String, List<Department>> tree,
    int level,
  ) {
    final children = tree[department.id] ?? [];
    final hasChildren = children.isNotEmpty;
    final isExpanded = _expandedNodes.contains(department.id);
    final levelIndent = level * 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Карточка подразделения
        InkWell(
          onTap: () {
            // Переход на детальную страницу при клике на карточку
            widget.onDepartmentTap?.call(department.id);
          },
          child: Container(
            margin: EdgeInsets.only(
              left: 16.0 + levelIndent,
              right: 16.0,
              top: 4.0,
              bottom: 4.0,
            ),
            decoration: BoxDecoration(
              color: _getDepartmentColor(level),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Визуальные линии иерархии
                if (level > 0) ...[
                  SizedBox(
                    width: levelIndent,
                    child: CustomPaint(
                      painter: _HierarchyLinePainter(level),
                      size: Size(levelIndent, 60),
                    ),
                  ),
                ],
                // Иконка раскрытия/сворачивания (если есть дети)
                if (hasChildren)
                  InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedNodes.remove(department.id);
                        } else {
                          _expandedNodes.add(department.id);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade700,
                        size: 24,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 40),
                // Иконка типа подразделения
                Icon(
                  hasChildren ? Icons.folder : Icons.business,
                  color: Colors.grey.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                // Информация о подразделении
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (department.description != null &&
                            department.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            department.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            if (department.manager != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    department.manager!.fullName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            if (department.employeesCount != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${department.employeesCount}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            if (hasChildren)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.folder,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${children.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Дочерние подразделения (если раскрыто)
        if (hasChildren && isExpanded)
          ...children.map((child) => _buildAccordionNode(child, tree, level + 1)),
      ],
    );
  }

  /// Строит узел бизнеса для десктопного вида
  Widget _buildBusinessNode(String businessName) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24.0,
        vertical: 16.0,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business, color: Colors.blue.shade700, size: 28),
          const SizedBox(width: 12),
          Text(
            businessName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  /// Строит дерево подразделений
  Map<String, List<Department>> _buildTree(List<Department> departments) {
    final Map<String, List<Department>> tree = {};
    final Map<String, Department> deptMap = {};

    // Создаем карту подразделений
    for (final dept in departments) {
      deptMap[dept.id] = dept;
    }

    // Группируем по parentId
    for (final dept in departments) {
      final parentId = dept.parentId ?? 'root';
      tree.putIfAbsent(parentId, () => []).add(dept);
    }

    return tree;
  }

  /// Строит виджет дерева
  Widget _buildTreeWidget(Map<String, List<Department>> tree, int level) {
    final rootDepartments = tree['root'] ?? [];

    if (rootDepartments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Строим дерево по уровням
    return _buildTreeByLevels(tree);
  }

  /// Строит дерево по уровням
  Widget _buildTreeByLevels(Map<String, List<Department>> tree) {
    // Собираем все уровни
    final levels = <int, List<Department>>{};
    
    // Начинаем с корневого уровня
    final rootDepts = tree['root'] ?? [];
    if (rootDepts.isEmpty) return const SizedBox.shrink();
    
    levels[0] = rootDepts;
    
    // Рекурсивно собираем все уровни
    void collectLevel(List<Department> parents, int currentLevel) {
      final children = <Department>[];
      for (final parent in parents) {
        final parentChildren = tree[parent.id] ?? [];
        children.addAll(parentChildren);
      }
      
      if (children.isNotEmpty) {
        levels[currentLevel + 1] = children;
        collectLevel(children, currentLevel + 1);
      }
    }
    
    collectLevel(rootDepts, 0);
    
    // Строим виджет для каждого уровня
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: levels.entries.map((entry) {
        final level = entry.key;
        final departments = entry.value;
        
        return Column(
          children: [
            if (level > 0) ...[
              const SizedBox(height: 24),
              // Вертикальная линия
              Container(
                height: 20,
                width: 2,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 4),
            ],
            // Ряд подразделений этого уровня
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16.0,
              runSpacing: 16.0,
              children: departments.map((dept) {
                return _buildDepartmentNode(dept, level, tree);
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  /// Строит узел подразделения
  Widget _buildDepartmentNode(
    Department department,
    int level,
    Map<String, List<Department>> tree,
  ) {
    final children = tree[department.id] ?? [];
    final hasChildren = children.isNotEmpty;

    return GestureDetector(
      onTap: () => widget.onDepartmentTap?.call(department.id),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
        decoration: BoxDecoration(
          color: _getDepartmentColor(level),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 220,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              department.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (department.description != null &&
                department.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                department.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
            if (department.manager != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      department.manager!.fullName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
            if (department.employeesCount != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${department.employeesCount}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
            if (hasChildren) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${children.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Получает цвет для подразделения в зависимости от уровня
  Color _getDepartmentColor(int level) {
    final colors = [
      Colors.blue.shade50,
      Colors.green.shade50,
      Colors.orange.shade50,
      Colors.purple.shade50,
      Colors.red.shade50,
      Colors.teal.shade50,
      Colors.pink.shade50,
      Colors.indigo.shade50,
    ];
    return colors[level % colors.length];
  }
}

/// CustomPainter для рисования линий иерархии
class _HierarchyLinePainter extends CustomPainter {
  final int level;

  _HierarchyLinePainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Рисуем вертикальные линии для каждого уровня
    for (int i = 0; i < level; i++) {
      final x = (i + 1) * 24.0 - 12.0;
      // Вертикальная линия
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Рисуем горизонтальную линию от последней вертикальной к элементу
    if (level > 0) {
      final lastVerticalX = level * 24.0 - 12.0;
      final horizontalY = size.height / 2;
      canvas.drawLine(
        Offset(lastVerticalX, horizontalY),
        Offset(size.width, horizontalY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HierarchyLinePainter oldDelegate) {
    return oldDelegate.level != level;
  }
}
