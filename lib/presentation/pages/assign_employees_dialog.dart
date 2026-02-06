import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';

/// Диалог для назначения сотрудников в подразделение
class AssignEmployeesDialog extends StatefulWidget {
  final Department department;
  final VoidCallback onEmployeesAssigned;

  const AssignEmployeesDialog({
    super.key,
    required this.department,
    required this.onEmployeesAssigned,
  });

  @override
  State<AssignEmployeesDialog> createState() => _AssignEmployeesDialogState();
}

class _AssignEmployeesDialogState extends State<AssignEmployeesDialog> {
  final Set<String> _selectedEmploymentIds = {};

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final departmentProvider = Provider.of<DepartmentProvider>(context);

    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) {
      return AlertDialog(
        title: const Text('Ошибка'),
        content: const Text('Компания не выбрана'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    }

    final employees = profileProvider.getEmployeesForBusiness(selectedBusiness.id);
    final currentEmployees = departmentProvider.currentDepartmentEmployees ?? [];
    final currentEmploymentIds = currentEmployees
        .map((e) => e['employmentId'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    // Фильтруем сотрудников, исключая уже назначенных
    final availableEmployees = employees
            ?.where((e) =>
                e.employmentId != null &&
                !currentEmploymentIds.contains(e.employmentId))
            .toList() ??
        [];

    return AlertDialog(
      title: const Text('Добавить сотрудников'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выберите сотрудников для добавления в подразделение:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (availableEmployees.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Нет доступных сотрудников',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableEmployees.length,
                  itemBuilder: (context, index) {
                    final employee = availableEmployees[index];
                    final employmentId = employee.employmentId;
                    if (employmentId == null) return const SizedBox.shrink();

                    final isSelected = _selectedEmploymentIds.contains(employmentId);

                    return CheckboxListTile(
                      title: Text(employee.fullName),
                      subtitle: employee.position != null
                          ? Text(employee.position!)
                          : null,
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedEmploymentIds.add(employmentId);
                          } else {
                            _selectedEmploymentIds.remove(employmentId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            if (_selectedEmploymentIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Выбрано: ${_selectedEmploymentIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: const Text('Отмена'),
        ),
        Consumer<DepartmentProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: (_selectedEmploymentIds.isEmpty || provider.isLoading)
                  ? null
                  : () => _assignEmployees(provider),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Добавить'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _assignEmployees(DepartmentProvider provider) async {
    if (_selectedEmploymentIds.isEmpty) return;

    final success = await provider.assignEmployees(
      widget.department.id,
      _selectedEmploymentIds.toList(),
    );

    if (!mounted) return;

    if (success) {
      context.pop();
      widget.onEmployeesAssigned();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Добавлено сотрудников: ${_selectedEmploymentIds.length}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Ошибка при добавлении сотрудников',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

