import 'package:flutter/material.dart';
import '../../domain/entities/department.dart';

/// Виджет для отображения графа организационной структуры
class DepartmentTreeGraph extends StatelessWidget {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Бизнес вверху
              if (businessName != null) ...[
                _buildBusinessNode(businessName!),
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
      ),
    );
  }

  /// Строит узел бизнеса
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

