import 'package:flutter/material.dart';
import '../../domain/entities/department.dart';

/// Виджет для отображения графа организационной структуры
class DepartmentTreeGraph extends StatelessWidget {
  final List<Department> departments;
  final Function(String departmentId)? onDepartmentTap;

  const DepartmentTreeGraph({
    super.key,
    required this.departments,
    this.onDepartmentTap,
  });

  @override
  Widget build(BuildContext context) {
    if (departments.isEmpty) {
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
    final tree = _buildTree(departments);
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _buildTreeWidget(tree, 0),
        ),
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

    if (rootDepartments.isEmpty && tree.length == 1) {
      // Если нет корневых, берем первое подразделение
      final firstKey = tree.keys.first;
      if (firstKey != 'root') {
        final dept = departments.firstWhere((d) => d.id == firstKey);
        return _buildDepartmentNode(dept, level, tree);
      }
    }

    if (rootDepartments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rootDepartments.map((dept) {
        return _buildDepartmentNode(dept, level, tree);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Отступ для уровня вложенности
            SizedBox(width: level * 40.0),
            // Узел подразделения
            GestureDetector(
              onTap: () => onDepartmentTap?.call(department.id),
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
                  minWidth: 200,
                  maxWidth: 250,
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
                      ),
                    ],
                    if (department.manager != null) ...[
                      const SizedBox(height: 4),
                      Row(
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
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (department.employeesCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
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
                        children: [
                          Icon(
                            Icons.folder,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${children.length} подразделений',
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
            ),
          ],
        ),
        // Дочерние подразделения
        if (hasChildren) ...[
          const SizedBox(height: 16),
          ...children.map((child) {
            return _buildDepartmentNode(child, level + 1, tree);
          }),
        ],
      ],
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

