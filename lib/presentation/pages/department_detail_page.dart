import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';
import 'assign_manager_dialog.dart';
import 'assign_employees_dialog.dart';
import 'create_department_dialog.dart';

/// Детальная страница подразделения
class DepartmentDetailPage extends StatefulWidget {
  final String departmentId;

  const DepartmentDetailPage({
    super.key,
    required this.departmentId,
  });

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider =
          Provider.of<DepartmentProvider>(context, listen: false);
      provider.loadDepartmentDetails(widget.departmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подразделение'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<DepartmentProvider>(
            builder: (context, provider, child) {
              final department = provider.currentDepartment;
              if (department == null) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.add_business),
                tooltip: 'Создать дочернее подразделение',
                onPressed: () => _showCreateChildDepartmentDialog(
                  context,
                  department,
                  provider,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DepartmentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentDepartment == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.currentDepartment == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadDepartmentDetails(
                      widget.departmentId,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final department = provider.currentDepartment;
          if (department == null) {
            return const Center(child: Text('Подразделение не найдено'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Информация о подразделении
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          department.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (department.description != null &&
                            department.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            department.description!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInfoRow('ID', department.id),
                        if (department.business != null)
                          _buildInfoRow(
                            'Бизнес',
                            department.business!.name,
                          ),
                        if (department.parent != null)
                          _buildInfoRow(
                            'Родительское подразделение',
                            department.parent!.name,
                          ),
                        _buildInfoRow(
                          'Дата создания',
                          department.createdAt.toString().split(' ').first,
                        ),
                        _buildInfoRow(
                          'Дата обновления',
                          department.updatedAt.toString().split(' ').first,
                        ),
                        if (department.employeesCount != null)
                          _buildInfoRow(
                            'Количество сотрудников',
                            '${department.employeesCount}',
                          ),
                        if (department.childrenCount != null)
                          _buildInfoRow(
                            'Количество дочерних подразделений',
                            '${department.childrenCount}',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Дочерние подразделения
                if (department.children.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Дочерние подразделения',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...department.children.map((child) {
                            return ListTile(
                              leading: const Icon(Icons.business),
                              title: Text(child.name),
                              subtitle: child.description != null
                                  ? Text(child.description!)
                                  : null,
                              onTap: () {
                                Navigator.of(context).pushReplacementNamed(
                                  '/department_detail',
                                  arguments: child.id,
                                );
                              },
                              trailing: const Icon(Icons.arrow_forward_ios,
                                  size: 16),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                // Менеджер подразделения
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Руководитель',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Consumer<ProfileProvider>(
                              builder: (context, profileProvider, child) {
                                final isGeneralDirector =
                                    profileProvider.profile?.orgStructure
                                            .isGeneralDirector ??
                                        false;
                                
                                if (!isGeneralDirector) {
                                  return const SizedBox.shrink();
                                }
                                
                                return TextButton.icon(
                                  onPressed: () => _showAssignManagerDialog(
                                    context,
                                    department,
                                    provider,
                                  ),
                                  icon: const Icon(Icons.person_add),
                                  label: Text(
                                    department.managerId == null
                                        ? 'Назначить'
                                        : 'Изменить',
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        if (department.manager != null) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person),
                            title: Text(
                              department.manager!.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(department.manager!.email),
                                if (department.manager!.username.isNotEmpty)
                                  Text('@${department.manager!.username}'),
                              ],
                            ),
                          ),
                          Consumer<ProfileProvider>(
                            builder: (context, profileProvider, child) {
                              final isGeneralDirector =
                                  profileProvider.profile?.orgStructure
                                          .isGeneralDirector ??
                                      false;
                              
                              if (!isGeneralDirector) {
                                return const SizedBox.shrink();
                              }
                              
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _removeManager(
                                      context,
                                      department,
                                      provider,
                                    ),
                                    child: const Text(
                                      'Убрать менеджера',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ] else if (department.managerId != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ID менеджера: ${department.managerId}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Consumer<ProfileProvider>(
                            builder: (context, profileProvider, child) {
                              final isGeneralDirector =
                                  profileProvider.profile?.orgStructure
                                          .isGeneralDirector ??
                                      false;
                              
                              if (!isGeneralDirector) {
                                return const SizedBox.shrink();
                              }
                              
                              return Column(
                                children: [
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: () => _removeManager(
                                      context,
                                      department,
                                      provider,
                                    ),
                                    child: const Text(
                                      'Убрать менеджера',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ] else
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Менеджер не назначен',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Сотрудники подразделения
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Сотрудники',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showAssignEmployeesDialog(
                                context,
                                department,
                                provider,
                              ),
                              icon: const Icon(Icons.group_add),
                              label: const Text('Добавить'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildEmployeesList(provider),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeesList(DepartmentProvider provider) {
    final department = provider.currentDepartment;
    
    // Сначала проверяем сотрудников из самого подразделения
    if (department != null && department.employees.isNotEmpty) {
      return Column(
        children: department.employees.map((employee) {
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(employee.fullName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.email),
                if (employee.position != null)
                  Text('Должность: ${employee.position}'),
                if (employee.orgPosition != null)
                  Text('Орг. позиция: ${employee.orgPosition}'),
                if (employee.phone != null) Text('Телефон: ${employee.phone}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeEmployee(
                context,
                department.id,
                employee.id, // Используем id как employmentId
                provider,
              ),
              tooltip: 'Убрать из подразделения',
            ),
          );
        }).toList(),
      );
    }

    // Иначе используем старый формат из провайдера
    final employees = provider.currentDepartmentEmployees;

    if (employees == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (employees.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'Сотрудники не назначены',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: employees.map((employee) {
        final employmentId = employee['employmentId'] as String?;
        final employeeData = employee['employee'] as Map<String, dynamic>?;
        final firstName = employeeData?['firstName'] as String? ?? '';
        final lastName = employeeData?['lastName'] as String? ?? '';
        final patronymic = employeeData?['patronymic'] as String?;
        final fullName = [lastName, firstName, patronymic]
            .where((s) => s != null && s.isNotEmpty)
            .join(' ');

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(fullName.isEmpty ? 'Неизвестный' : fullName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (employeeData?['email'] != null)
                Text(employeeData!['email'] as String),
              if (employmentId != null)
                Text('Employment ID: $employmentId'),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.red),
            onPressed: employmentId != null
                ? () => _removeEmployee(
                      context,
                      provider.currentDepartment!.id,
                      employmentId,
                      provider,
                    )
                : null,
            tooltip: 'Убрать из подразделения',
          ),
        );
      }).toList(),
    );
  }

  void _showAssignManagerDialog(
    BuildContext context,
    Department department,
    DepartmentProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignManagerDialog(
        department: department,
        onManagerAssigned: () {
          provider.loadDepartmentDetails(department.id);
        },
      ),
    );
  }

  void _showAssignEmployeesDialog(
    BuildContext context,
    Department department,
    DepartmentProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AssignEmployeesDialog(
        department: department,
        onEmployeesAssigned: () {
          provider.loadDepartmentDetails(department.id);
        },
      ),
    );
  }

  Future<void> _removeManager(
    BuildContext context,
    Department department,
    DepartmentProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Убрать менеджера'),
        content: const Text(
          'Вы уверены, что хотите убрать менеджера из этого подразделения?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Убрать',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final isGeneralDirector =
          profileProvider.profile?.orgStructure.isGeneralDirector ?? false;
      
      final success = await provider.removeManager(
        department.id,
        isGeneralDirector,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Менеджер убран'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Ошибка при удалении менеджера'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeEmployee(
    BuildContext context,
    String departmentId,
    String employmentId,
    DepartmentProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Убрать сотрудника'),
        content: const Text(
          'Вы уверены, что хотите убрать этого сотрудника из подразделения?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Убрать',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.removeEmployee(departmentId, employmentId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сотрудник убран из подразделения'),
            duration: Duration(seconds: 2),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'Ошибка при удалении сотрудника',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCreateChildDepartmentDialog(
    BuildContext context,
    Department department,
    DepartmentProvider provider,
  ) {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Компания не выбрана'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CreateDepartmentDialog(
        businessId: selectedBusiness.id,
        parentId: department.id, // Передаем ID текущего подразделения как родителя
        onDepartmentCreated: () {
          // Перезагружаем детальную информацию о подразделении
          provider.loadDepartmentDetails(department.id);
          // Перезагружаем дерево подразделений
          provider.loadDepartmentsTree(selectedBusiness.id);
        },
      ),
    );
  }
}

