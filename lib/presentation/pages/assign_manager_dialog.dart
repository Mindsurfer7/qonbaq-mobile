import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/employee.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';
import '../../domain/repositories/user_repository.dart';
import '../widgets/user_selector_widget.dart';

/// Диалог для назначения менеджера подразделения
class AssignManagerDialog extends StatefulWidget {
  final Department department;
  final VoidCallback onManagerAssigned;

  const AssignManagerDialog({
    super.key,
    required this.department,
    required this.onManagerAssigned,
  });

  @override
  State<AssignManagerDialog> createState() => _AssignManagerDialogState();
}

class _AssignManagerDialogState extends State<AssignManagerDialog> {
  Employee? _selectedEmployee;

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final userRepository = Provider.of<UserRepository>(context);

    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) {
      return AlertDialog(
        title: const Text('Ошибка'),
        content: const Text('Компания не выбрана'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Назначить менеджера'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выберите сотрудника, который будет руководителем подразделения:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildEmployeeSelector(
              context,
              selectedBusiness.id,
              userRepository,
              widget.department.managerId,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        Consumer<DepartmentProvider>(
          builder: (context, provider, child) {
            return ElevatedButton(
              onPressed: (_selectedEmployee == null || provider.isLoading)
                  ? null
                  : () => _assignManager(provider),
              child: provider.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Назначить'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmployeeSelector(
    BuildContext context,
    String businessId,
    UserRepository userRepository,
    String? currentManagerId,
  ) {
    return UserSelectorWidget(
      businessId: businessId,
      userRepository: userRepository,
      selectedUserId: currentManagerId,
      label: 'Менеджер',
      required: true,
      onUserSelected: (userId) {
        setState(() {
          if (userId != null) {
            // Находим сотрудника в списке
            final profileProvider =
                Provider.of<ProfileProvider>(context, listen: false);
            final employees =
                profileProvider.getEmployeesForBusiness(businessId);
            if (employees != null) {
              try {
                _selectedEmployee =
                    employees.firstWhere((e) => e.id == userId);
              } catch (e) {
                _selectedEmployee = null;
              }
            }
          } else {
            _selectedEmployee = null;
          }
        });
      },
    );
  }

  Future<void> _assignManager(DepartmentProvider provider) async {
    if (_selectedEmployee == null) return;

    final success = await provider.setManager(
      widget.department.id,
      _selectedEmployee!.id,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      widget.onManagerAssigned();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Менеджер успешно назначен'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'Ошибка при назначении менеджера',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

