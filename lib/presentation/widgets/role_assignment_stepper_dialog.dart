import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/employment_with_role.dart';
import '../../domain/usecases/assign_functional_roles.dart';
import '../../data/models/business_model.dart';
import '../providers/role_assignment_form_provider.dart';
import '../providers/roles_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/searchable_dropdown.dart';

/// Многошаговый диалог для назначения функциональных ролей
class RoleAssignmentStepperDialog extends StatefulWidget {
  final String businessId;

  const RoleAssignmentStepperDialog({super.key, required this.businessId});

  @override
  State<RoleAssignmentStepperDialog> createState() =>
      _RoleAssignmentStepperDialogState();
}

class _RoleAssignmentStepperDialogState
    extends State<RoleAssignmentStepperDialog> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isUpdatingBusiness = false;
  bool _showEmployeeSelector =
      false; // Показывать ли селектор сотрудника на первом шаге
  final List<String> _roleTitles = [
    'Кто ответственен за согласования?',
    'Кто отвечает за выдачу денег?',
  ];
  final List<String> _roleDescriptions = [
    'Если вы будете утверждать все финансовые и не финансовые согласования самостоятельно, то нажмите "Следующий шаг". Если это будет делать ваше доверенное лицо, нажмите "Выбрать сотрудника".',
    'Выберите сотрудника, который будет отвечать за выдачу денег. Это может быть бухгалтер или другой сотрудник.',
  ];
  final List<String?> _selectedEmploymentIds = [null, null];
  final List<GlobalKey<FormFieldState>> _formFieldKeys = [
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

    final formProvider = Provider.of<RoleAssignmentFormProvider>(
      context,
      listen: false,
    );
    switch (stepIndex) {
      case 0:
        formProvider.setApprovalAuthorize(employmentId);
        break;
      case 1:
        formProvider.setMoneyIssuer(employmentId);
        break;
    }
  }

  Future<void> _skipApprovalAuthorizer() async {
    // Пользователь выбрал утверждать согласования самостоятельно
    if (_isUpdatingBusiness) return;

    setState(() {
      _isUpdatingBusiness = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      // Отправляем только поле requiresApprovalAuthorizer
      final updates = BusinessModel.toPartialUpdateJson(
        requiresApprovalAuthorizer: false,
      );

      final result = await profileProvider.updateBusinessPartialCall(
        widget.businessId,
        updates,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isUpdatingBusiness = false;
          });
        },
        (_) {
          // Успешно обновлено, переходим к следующему шагу
          setState(() {
            _isUpdatingBusiness = false;
            _currentStep++;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isUpdatingBusiness = false;
        });
      }
    }
  }

  Future<void> _selectEmployeeForApproval() async {
    // Пользователь выбрал выбрать сотрудника для согласований
    if (_isUpdatingBusiness) return;

    setState(() {
      _isUpdatingBusiness = true;
    });

    try {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );

      // Отправляем только поле requiresApprovalAuthorizer
      final updates = BusinessModel.toPartialUpdateJson(
        requiresApprovalAuthorizer: true,
      );

      final result = await profileProvider.updateBusinessPartialCall(
        widget.businessId,
        updates,
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isUpdatingBusiness = false;
          });
        },
        (_) {
          // Успешно обновлено, показываем селектор сотрудника
          setState(() {
            _isUpdatingBusiness = false;
            _showEmployeeSelector = true;
          });
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isUpdatingBusiness = false;
        });
      }
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

    if (_currentStep < 1) {
      setState(() {
        _currentStep++;
        _showEmployeeSelector = false; // Сбрасываем флаг для следующего шага
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
    // Для первого шага (согласования) - если выбран сотрудник
    if (_currentStep == 0) {
      return _showEmployeeSelector &&
          _selectedEmploymentIds[_currentStep] != null;
    }
    // Для второго шага (выдача денег) - если выбран сотрудник
    return _selectedEmploymentIds[_currentStep] != null;
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

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formProvider = Provider.of<RoleAssignmentFormProvider>(
        context,
        listen: false,
      );
      final assignments = formProvider.getAssignments();

      // Проверяем, что если мы на втором шаге, то должен быть выбран сотрудник для выдачи денег
      if (_currentStep == 1 && _selectedEmploymentIds[1] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Необходимо выбрать сотрудника для выдачи денег'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Если нет назначений, но мы дошли до финального шага, это нормально
      // (например, если пользователь пропустил первый шаг и не выбрал сотрудника для второго)
      if (assignments.isEmpty && _selectedEmploymentIds[1] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Необходимо выбрать сотрудника для выдачи денег'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final assignFunctionalRoles = Provider.of<AssignFunctionalRoles>(
        context,
        listen: false,
      );

      final result = await assignFunctionalRoles.call(
        AssignFunctionalRolesParams(
          businessId: widget.businessId,
          assignments: assignments,
        ),
      );

      if (!mounted) return;

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        },
        (_) {
          // Успешное назначение
          formProvider.clear();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Функциональные роли успешно назначены'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
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
                          'Назначение функциональных ролей',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Шаг ${_currentStep + 1} из 2',
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
                children: List.generate(2, (index) {
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < 1 ? 4 : 0),
                      decoration: BoxDecoration(
                        color:
                            index <= _currentStep
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
                    _currentStep == 0
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Если вы будете утверждать все финансовые и не финансовые согласования самостоятельно, то нажмите "Следующий шаг".',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'Если это будет делать ваше доверенное лицо, нажмите "Выбрать сотрудника".',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        )
                        : Text(
                          _roleDescriptions[_currentStep],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    const SizedBox(height: 24),
                    // Для первого шага показываем кнопки выбора или селектор
                    if (_currentStep == 0) ...[
                      if (!_showEmployeeSelector) ...[
                        // Показываем две кнопки выбора
                        ElevatedButton(
                          onPressed:
                              _isUpdatingBusiness
                                  ? null
                                  : _skipApprovalAuthorizer,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child:
                              _isUpdatingBusiness
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Следующий шаг'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed:
                              _isUpdatingBusiness
                                  ? null
                                  : _selectEmployeeForApproval,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                          ),
                          child:
                              _isUpdatingBusiness
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Выбрать сотрудника'),
                        ),
                      ] else ...[
                        // Показываем селектор сотрудника
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
                    ] else ...[
                      // Для второго шага всегда показываем селектор
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
                  ],
                ),
              ),
            ),
            // Кнопки навигации
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
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
                  // Для первого шага кнопка "Далее" показывается только если выбран сотрудник
                  if (_currentStep == 0 && _showEmployeeSelector) ...[
                    ElevatedButton(
                      onPressed:
                          (_isSubmitting ||
                                  _isUpdatingBusiness ||
                                  !_canProceedToNext())
                              ? null
                              : _nextStep,
                      child:
                          _isSubmitting || _isUpdatingBusiness
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Далее'),
                    ),
                  ] else if (_currentStep == 1) ...[
                    // Для второго шага показываем кнопку "Завершить"
                    ElevatedButton(
                      onPressed:
                          (_isSubmitting || !_canProceedToNext())
                              ? null
                              : _submit,
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Завершить'),
                    ),
                  ] else ...[
                    // Для первого шага без выбора сотрудника кнопка не нужна
                    const SizedBox.shrink(),
                  ],
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
                final firstName =
                    employment.user.firstName?.toLowerCase() ?? '';
                final lastName = employment.user.lastName?.toLowerCase() ?? '';
                final patronymic =
                    employment.user.patronymic?.toLowerCase() ?? '';
                final position = employment.position?.toLowerCase() ?? '';

                return fullName.contains(query) ||
                    firstName.contains(query) ||
                    lastName.contains(query) ||
                    patronymic.contains(query) ||
                    position.contains(query);
              },
              itemBuilder: (context, employment) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
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
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}
