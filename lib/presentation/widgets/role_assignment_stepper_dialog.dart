import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/employment_with_role.dart';
import '../providers/role_assignment_form_provider.dart';
import '../providers/roles_provider.dart';
import '../widgets/searchable_dropdown.dart';

/// Многошаговый диалог для назначения трех основных ролей
class RoleAssignmentStepperDialog extends StatefulWidget {
  final String businessId;

  const RoleAssignmentStepperDialog({
    super.key,
    required this.businessId,
  });

  @override
  State<RoleAssignmentStepperDialog> createState() =>
      _RoleAssignmentStepperDialogState();
}

class _RoleAssignmentStepperDialogState
    extends State<RoleAssignmentStepperDialog> {
  int _currentStep = 0;
  final List<String> _roleTitles = [
    'Кто утверждает финальный документ или заявку?',
    'Кто выдает деньги?',
    'Кто оформляет документы (подшивает документы)?',
  ];
  final List<String> _roleDescriptions = [
    'Выберите сотрудника, который будет утверждать финальные документы и заявки. Обычно это генеральный директор.',
    'Выберите сотрудника, который будет выдавать деньги. Это может быть бухгалтер или другое назначенное лицо.',
    'Выберите сотрудника, который будет оформлять документы. Обычно это кадровик или другое назначенное лицо.',
  ];
  final List<String?> _selectedEmploymentIds = [null, null, null];
  final List<GlobalKey<FormFieldState>> _formFieldKeys = [
    GlobalKey<FormFieldState>(),
    GlobalKey<FormFieldState>(),
    GlobalKey<FormFieldState>(),
  ];

  @override
  void initState() {
    super.initState();
    _loadEmployments();
  }

  void _loadEmployments() {
    final rolesProvider = Provider.of<RolesProvider>(context, listen: false);
    if (rolesProvider.employments == null) {
      rolesProvider.loadEmployments(widget.businessId);
    }
  }

  void _onEmployeeSelected(int stepIndex, String? employmentId) {
    setState(() {
      _selectedEmploymentIds[stepIndex] = employmentId;
    });

    final formProvider =
        Provider.of<RoleAssignmentFormProvider>(context, listen: false);
    switch (stepIndex) {
      case 0:
        formProvider.setFinalApprover(employmentId);
        break;
      case 1:
        formProvider.setMoneyIssuer(employmentId);
        break;
      case 2:
        formProvider.setDocumentProcessor(employmentId);
        break;
    }
  }

  void _nextStep() {
    // Валидируем текущий шаг перед переходом
    final currentFieldKey = _formFieldKeys[_currentStep];
    if (currentFieldKey.currentState != null) {
      currentFieldKey.currentState!.validate();
      if (!currentFieldKey.currentState!.isValid) {
        return; // Не переходим, если валидация не прошла
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  bool _canProceedToNext() {
    return _selectedEmploymentIds[_currentStep] != null;
  }

  bool _isLastStep() {
    return _currentStep == 2;
  }

  Future<void> _submit() async {
    // Валидируем последний шаг перед отправкой
    final lastFieldKey = _formFieldKeys[_currentStep];
    if (lastFieldKey.currentState != null) {
      lastFieldKey.currentState!.validate();
      if (!lastFieldKey.currentState!.isValid) {
        return; // Не отправляем, если валидация не прошла
      }
    }

    // Данные уже сохранены в провайдер через _onEmployeeSelected
    // TODO: Здесь нужно будет определить, как назначать эти роли
    // Возможно, это будут специальные коды ролей или отдельный API endpoint
    // Пока просто переходим на страницу распределения ролей

    if (mounted) {
      Navigator.of(context).pop();
      Navigator.of(context).pushNamed('/roles-assignment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Заголовок
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Назначение основных ролей',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Шаг ${_currentStep + 1} из 3',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Индикатор прогресса
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(3, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index < 2 ? 4 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Контент шага
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _roleTitles[_currentStep],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _roleDescriptions[_currentStep],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Consumer<RolesProvider>(
                      builder: (context, rolesProvider, child) {
                        if (rolesProvider.isLoading &&
                            rolesProvider.employments == null) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (rolesProvider.error != null &&
                            rolesProvider.employments == null) {
                          return Column(
                            children: [
                              Text(
                                rolesProvider.error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  rolesProvider.loadEmployments(
                                    widget.businessId,
                                  );
                                },
                                child: const Text('Повторить'),
                              ),
                            ],
                          );
                        }

                        final employments = rolesProvider.employments;
                        if (employments == null || employments.isEmpty) {
                          return const Text('Нет доступных сотрудников');
                        }

                        return _buildEmployeeSelector(
                          employments,
                          _currentStep,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Кнопки навигации
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _previousStep,
                      child: const Text('Назад'),
                    )
                  else
                    const SizedBox.shrink(),
                  ElevatedButton(
                    onPressed: _canProceedToNext()
                        ? (_isLastStep() ? _submit : _nextStep)
                        : null,
                    child: Text(_isLastStep() ? 'Завершить' : 'Далее'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeSelector(
    List<EmploymentWithRole> employments,
    int stepIndex,
  ) {
    final selectedEmploymentId = _selectedEmploymentIds[stepIndex];
    EmploymentWithRole? selectedEmployment;
    if (selectedEmploymentId != null) {
      try {
        selectedEmployment = employments.firstWhere(
          (emp) => emp.id == selectedEmploymentId,
        );
      } catch (e) {
        selectedEmployment = null;
      }
    }

    return FormField<EmploymentWithRole>(
      key: _formFieldKeys[stepIndex],
      initialValue: selectedEmployment,
      autovalidateMode: AutovalidateMode.disabled,
      validator: (value) {
        if (value == null) {
          return 'Выберите сотрудника';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchableDropdown<EmploymentWithRole>(
              value: selectedEmployment,
              items: employments,
              getDisplayText: (employment) => employment.fullName,
              getSubtitleText: (employment) => employment.position,
              labelText: 'Выберите сотрудника',
              required: true,
              autovalidateMode: AutovalidateMode.disabled,
              onChanged: (employment) {
                field.didChange(employment);
                _onEmployeeSelected(stepIndex, employment?.id);
              },
              validator: (value) {
                return field.errorText;
              },
              filterFunction: (employment, query) {
                final fullName = employment.fullName.toLowerCase();
                final firstName = employment.user.firstName?.toLowerCase() ?? '';
                final lastName = employment.user.lastName?.toLowerCase() ?? '';
                final patronymic = employment.user.patronymic?.toLowerCase() ?? '';
                final position = employment.position?.toLowerCase() ?? '';
                
                return fullName.contains(query) ||
                    firstName.contains(query) ||
                    lastName.contains(query) ||
                    patronymic.contains(query) ||
                    position.contains(query);
              },
              itemBuilder: (context, employment) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        employment.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      if (employment.position != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          employment.position!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Text(
                field.errorText ?? '',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
