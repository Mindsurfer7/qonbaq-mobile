import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/business.dart';
import '../../domain/usecases/update_employment.dart';
import 'employment_form_widget.dart';

/// Виджет для управления шагами регистрации
class RegistrationStepperWidget extends StatefulWidget {
  final String? inviteCode;

  const RegistrationStepperWidget({
    super.key,
    this.inviteCode,
  });

  @override
  State<RegistrationStepperWidget> createState() => _RegistrationStepperWidgetState();
}

class _RegistrationStepperWidgetState extends State<RegistrationStepperWidget> {
  int _currentStep = 0;
  bool _isLoading = false;
  String? _error;
  InviteType? _inviteType;
  Business? _currentBusiness;
  
  // Контроллеры формы регистрации
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // После регистрации нужно определить тип invite
    // Пока что будем определять по типу бизнеса после загрузки
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _determineInviteType() async {
    if (!mounted) return;
    
    final profileProvider = context.read<ProfileProvider>();
    await profileProvider.loadBusinesses();
    
    if (!mounted) return;
    
    // Проверяем тип первого бизнеса
    final businesses = profileProvider.businesses;
    if (businesses != null && businesses.isNotEmpty) {
      final business = businesses.first;
      _currentBusiness = business;
      // Если тип бизнеса = business, то invite type = business
      // Иначе invite type = family
      setState(() {
        _inviteType = business.type == BusinessType.business 
            ? InviteType.business 
            : InviteType.family;
      });
    }
  }

  Future<void> _handleRegistration({
    required String email,
    required String username,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: email,
      username: username,
      password: password,
      inviteCode: widget.inviteCode,
      firstName: firstName,
      lastName: lastName,
    );

    if (!mounted) return;

    if (success) {
      // Если нет invite кода, сразу переходим на workspace selector
      if (widget.inviteCode == null || widget.inviteCode!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _navigateToWorkspaceSelector();
        return;
      }

      // Если есть invite код, определяем тип invite по типу бизнеса
      await _determineInviteType();
      
      if (!mounted) return;
      
      // Если тип invite = business, переходим на второй шаг
      if (_inviteType == InviteType.business) {
        setState(() {
          _currentStep = 1;
          _isLoading = false;
        });
      } else {
        // Если тип invite = family или нет бизнеса, переходим на workspace selection
        setState(() {
          _isLoading = false;
        });
        _navigateToWorkspaceSelector();
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = authProvider.error;
      });
    }
  }


  void _navigateToWorkspaceSelector() {
    if (!mounted) return;
    // Показываем SnackBar до навигации, чтобы избежать ошибки с deactivated widget
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Регистрация успешна!'),
        backgroundColor: Colors.green,
      ),
    );
    // Используем addPostFrameCallback для навигации после отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/workspace-selector');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Всегда создаем 2 шага, чтобы избежать ошибки изменения количества шагов
    // Второй шаг будет скрыт, если тип не business
    final shouldShowSecondStep = _inviteType == InviteType.business;
    
    return PopScope(
      canPop: _currentStep == 0, // Можно вернуться назад только на первом шаге
      child: Stepper(
        currentStep: _currentStep,
        onStepContinue: null, // Убираем кнопку Continue
        onStepCancel: null, // Убираем кнопку Cancel
        controlsBuilder: (context, details) {
          // Не показываем стандартные кнопки управления шагами
          return const SizedBox.shrink();
        },
        steps: [
        // Шаг 1: Регистрация
        Step(
          title: const Text('Регистрация'),
          content: _buildRegistrationStep(),
          isActive: _currentStep == 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        // Шаг 2: Заполнение employment (показывается только для business типа)
        Step(
          title: const Text('Данные о трудоустройстве'),
          content: shouldShowSecondStep 
              ? _buildEmploymentStep()
              : const SizedBox.shrink(), // Пустой контент, если шаг не нужен
          isActive: _currentStep == 1 && shouldShowSecondStep,
          state: shouldShowSecondStep
              ? (_currentStep > 1 ? StepState.complete : StepState.indexed)
              : StepState.disabled,
        ),
      ],
      ),
    );
  }

  Widget _buildRegistrationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.inviteCode != null && widget.inviteCode!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Вы регистрируетесь по приглашению',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Неверный формат email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Имя пользователя',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              helperText: 'От 3 до 30 символов',
            ),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите имя пользователя';
              }
              if (value.length < 3 || value.length > 30) {
                return 'Имя пользователя должно быть от 3 до 30 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Имя',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.trim().isEmpty) {
                return 'Имя не может состоять только из пробелов';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Фамилия',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value != null && value.isNotEmpty && value.trim().isEmpty) {
                return 'Фамилия не может состоять только из пробелов';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Пароль',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
              helperText: 'От 6 до 100 символов',
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите пароль';
              }
              if (value.length < 6 || value.length > 100) {
                return 'Пароль должен быть от 6 до 100 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Подтвердите пароль',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Подтвердите пароль';
              }
              if (value != _passwordController.text) {
                return 'Пароли не совпадают';
              }
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : () {
              if (_formKey.currentState!.validate()) {
                _handleRegistration(
                  email: _emailController.text.trim(),
                  username: _usernameController.text.trim(),
                  password: _passwordController.text,
                  firstName: _firstNameController.text.trim().isNotEmpty
                      ? _firstNameController.text.trim()
                      : null,
                  lastName: _lastNameController.text.trim().isNotEmpty
                      ? _lastNameController.text.trim()
                      : null,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Зарегистрироваться'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmploymentStep() {
    final updateEmployment = context.read<UpdateEmployment>();
    
    return EmploymentFormWidget(
      inviteType: _inviteType,
      onSave: (data) async {
        final result = await updateEmployment.call(
          UpdateEmploymentParams(
            position: data['position'] as String?,
            positionType: data['positionType'] as String?,
            orgPosition: data['orgPosition'] as String?,
            workPhone: data['workPhone'] as String?,
            workExperience: data['workExperience'] as int?,
            accountability: data['accountability'] as String?,
            personnelNumber: data['personnelNumber'] as String?,
            hireDate: data['hireDate'] != null 
                ? DateTime.parse(data['hireDate'] as String)
                : null,
            roleCode: data['roleCode'] as String?,
            businessId: _currentBusiness?.id,
          ),
        );

        return result.fold(
          (failure) {
            throw Exception(failure.message);
          },
          (employment) {
            // Успешно сохранено
            _navigateToWorkspaceSelector();
            return {
              'success': true,
              'employment': employment,
            };
          },
        );
      },
    );
  }
}
