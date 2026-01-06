import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import 'searchable_dropdown.dart';

/// Виджет для выбора пользователя (исполнитель/поручитель)
class UserSelectorWidget extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final String? selectedUserId;
  final Function(String?) onUserSelected;
  final String label;
  final bool required;

  const UserSelectorWidget({
    super.key,
    required this.businessId,
    required this.userRepository,
    this.selectedUserId,
    required this.onUserSelected,
    required this.label,
    this.required = false,
  });

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  List<Employee>? _employees;
  bool _isLoading = false;
  String? _error;
  Employee? _selectedEmployee;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    if (widget.selectedUserId != null) {
      // Если уже выбран пользователь, найдем его в списке после загрузки
    }
  }

  @override
  void didUpdateWidget(UserSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedUserId != widget.selectedUserId ||
        oldWidget.businessId != widget.businessId) {
      _loadEmployees();
    }
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Пробуем получить из ProfileProvider (кэш)
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final cachedEmployees = profileProvider.getEmployeesForBusiness(
      widget.businessId,
    );

    if (cachedEmployees != null && cachedEmployees.isNotEmpty) {
      setState(() {
        _isLoading = false;
        _employees = cachedEmployees;
        // Находим выбранного сотрудника если есть selectedUserId
        if (widget.selectedUserId != null) {
          try {
            _selectedEmployee = cachedEmployees.firstWhere(
              (e) => e.id == widget.selectedUserId,
            );
          } catch (e) {
            _selectedEmployee = null;
          }
        }
      });
      return;
    }

    // Если нет в кэше, загружаем и сохраняем в провайдер
    final result = await widget.userRepository.getBusinessEmployees(
      widget.businessId,
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (employees) {
        // Сохраняем в ProfileProvider для переиспользования
        profileProvider.cacheEmployees(widget.businessId, employees);

        setState(() {
          _isLoading = false;
          _employees = employees;
          // Находим выбранного сотрудника если есть selectedUserId
          if (widget.selectedUserId != null) {
            try {
              _selectedEmployee = employees.firstWhere(
                (e) => e.id == widget.selectedUserId,
              );
            } catch (e) {
              _selectedEmployee = null;
            }
          }
        });
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DropdownButtonFormField(
        decoration: const InputDecoration(
          labelText: 'Загрузка...',
          border: OutlineInputBorder(),
        ),
        items: const [],
        onChanged: null,
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            items: const [],
            onChanged: null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Повторить'),
          ),
        ],
      );
    }

    if (_employees == null || _employees!.isEmpty) {
      return DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          helperText: 'Нет доступных сотрудников',
        ),
        items: const [],
        onChanged: null,
      );
    }

    return SearchableDropdown<Employee>(
      value: _selectedEmployee,
      items: _employees!,
      getDisplayText: (employee) => employee.fullName,
      getSubtitleText: (employee) => employee.role,
      labelText: widget.label,
      required: widget.required,
      onChanged: (employee) {
        setState(() {
          _selectedEmployee = employee;
        });
        widget.onUserSelected(employee?.id);
      },
      validator: widget.required
          ? (value) {
              if (value == null) {
                return 'Выберите ${widget.label.toLowerCase()}';
              }
              return null;
            }
          : null,
      // Функция фильтрации для поиска по имени, фамилии и отчеству
      filterFunction: (employee, query) {
        final fullName = employee.fullName.toLowerCase();
        final firstName = employee.firstName.toLowerCase();
        final lastName = employee.lastName.toLowerCase();
        final patronymic = employee.patronymic?.toLowerCase() ?? '';
        final role = employee.role?.toLowerCase() ?? '';
        
        return fullName.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query) ||
            patronymic.contains(query) ||
            role.contains(query);
      },
      // Виджет для отображения элемента в списке
      itemBuilder: (context, employee) {
        return SizedBox(
          height: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  employee.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
              if (employee.role != null && employee.role!.isNotEmpty)
                Flexible(
                  child: Text(
                    employee.role!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
