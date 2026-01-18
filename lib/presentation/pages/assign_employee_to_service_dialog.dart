import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/service.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/usecases/create_service_assignment.dart';
import '../providers/profile_provider.dart';

/// Диалог для назначения сотрудника на услугу
class AssignEmployeeToServiceDialog extends StatefulWidget {
  final Service service;

  const AssignEmployeeToServiceDialog({
    super.key,
    required this.service,
  });

  @override
  State<AssignEmployeeToServiceDialog> createState() =>
      _AssignEmployeeToServiceDialogState();
}

class _AssignEmployeeToServiceDialogState
    extends State<AssignEmployeeToServiceDialog> {
  String? _selectedEmploymentId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

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

    final employees = profileProvider.getEmployeesForBusiness(selectedBusiness.id);
    
    // Получаем уже назначенные employmentId
    final assignedEmploymentIds = widget.service.assignments
            ?.where((a) => a.employmentId != null)
            .map((a) => a.employmentId!)
            .toSet() ??
        {};

    // Фильтруем сотрудников, исключая уже назначенных
    final availableEmployees = employees
            ?.where((e) =>
                e.employmentId != null &&
                !assignedEmploymentIds.contains(e.employmentId))
            .toList() ??
        [];

    return AlertDialog(
      title: const Text('Назначить сотрудника'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Выберите сотрудника для назначения на услугу:',
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

                    return RadioListTile<String>(
                      title: Text(employee.fullName),
                      subtitle: employee.position != null
                          ? Text(employee.position!)
                          : null,
                      value: employmentId,
                      groupValue: _selectedEmploymentId,
                      onChanged: (value) {
                        setState(() {
                          _selectedEmploymentId = value;
                        });
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: (_selectedEmploymentId == null || _isLoading)
              ? null
              : () => _assignEmployee(),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Назначить'),
        ),
      ],
    );
  }

  Future<void> _assignEmployee() async {
    if (_selectedEmploymentId == null) return;

    setState(() {
      _isLoading = true;
    });

    final serviceRepository = Provider.of<ServiceRepository>(
      context,
      listen: false,
    );
    final createAssignment = CreateServiceAssignment(serviceRepository);
    final result = await createAssignment.call(
      CreateServiceAssignmentParams(
        serviceId: widget.service.id,
        employmentId: _selectedEmploymentId,
      ),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${failure.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      },
      (_) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Сотрудник успешно назначен'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}
