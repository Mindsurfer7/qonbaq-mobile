import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/credentials_storage.dart';
import '../../core/utils/deep_link_service.dart';
import '../widgets/registration_stepper_widget.dart';

/// Страница аутентификации с табами (логин/регистрация)
class AuthPage extends StatefulWidget {
  final String? inviteCode;

  const AuthPage({super.key, this.inviteCode});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Определяем начальный индекс таба: если есть invite код, начинаем с регистрации
    final initialIndex =
        (widget.inviteCode != null ||
                DeepLinkService.instance.pendingInviteCode != null)
            ? 1
            : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Если есть inviteCode, переключаемся на таб регистрации
    if (widget.inviteCode != null ||
        DeepLinkService.instance.pendingInviteCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController.animateTo(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qonbaq'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Вход', icon: Icon(Icons.login)),
            Tab(text: 'Регистрация', icon: Icon(Icons.person_add)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const LoginTab(),
          RegistrationStepperWidget(
            inviteCode:
                widget.inviteCode ?? DeepLinkService.instance.pendingInviteCode,
          ),
        ],
      ),
    );
  }
}

/// Таб входа
class LoginTab extends StatefulWidget {
  const LoginTab({super.key});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await CredentialsStorage.getSavedCredentials();
    if (mounted) {
      setState(() {
        if (credentials['email'] != null) {
          _emailController.text = credentials['email']!;
        }
        if (credentials['password'] != null) {
          _passwordController.text = credentials['password']!;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(email: email, password: password);

    if (!mounted) return;

    if (success) {
      // Сохраняем учетные данные после успешного входа
      await CredentialsStorage.saveCredentials(
        email: email,
        password: password,
      );
      Navigator.of(context).pushReplacementNamed('/business');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Успешный вход!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    _passwordFocusNode.requestFocus();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Неверный формат email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!authProvider.isLoading) {
                      _handleLogin();
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    return null;
                  },
                ),
                if (authProvider.error != null) ...[
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
                            authProvider.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      authProvider.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Войти'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Таб регистрации
class RegisterTab extends StatefulWidget {
  final String? inviteCode;

  const RegisterTab({super.key, this.inviteCode});

  @override
  State<RegisterTab> createState() => _RegisterTabState();
}

class _RegisterTabState extends State<RegisterTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  // final _usernameController = TextEditingController(); // Никнейм не используется
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  // final _usernameFocusNode = FocusNode(); // Никнейм не используется
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _inviteCode;

  @override
  void initState() {
    super.initState();
    // Получаем код приглашения из параметра или из deep link сервиса
    _inviteCode =
        widget.inviteCode ?? DeepLinkService.instance.pendingInviteCode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    // _usernameController.dispose(); // Никнейм не используется
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    // _usernameFocusNode.dispose(); // Никнейм не используется
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      // username не передаем, так как никнейм не используется
      password: _passwordController.text,
      inviteCode: _inviteCode,
    );

    // Очищаем код приглашения после использования
    if (_inviteCode != null) {
      DeepLinkService.instance.clearInviteCode();
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/workspace-selector');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Регистрация успешна!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Показываем информацию о коде приглашения, если он есть
                if (_inviteCode != null && _inviteCode!.isNotEmpty) ...[
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
                  focusNode: _emailFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) {
                    _passwordFocusNode
                        .requestFocus(); // Переходим сразу к паролю, так как никнейм закомментирован
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Неверный формат email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Поле никнейма закомментировано - никнейм не используется
                // TextFormField(
                //   controller: _usernameController,
                //   focusNode: _usernameFocusNode,
                //   decoration: const InputDecoration(
                //     labelText: 'Имя пользователя',
                //     prefixIcon: Icon(Icons.person),
                //     border: OutlineInputBorder(),
                //     helperText: 'От 3 до 30 символов',
                //   ),
                //   textInputAction: TextInputAction.next,
                //   onFieldSubmitted: (_) {
                //     _passwordFocusNode.requestFocus();
                //   },
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Введите имя пользователя';
                //     }
                //     if (value.length < 3 || value.length > 30) {
                //       return 'Имя пользователя должно быть от 3 до 30 символов';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                  onFieldSubmitted: (_) {
                    _confirmPasswordFocusNode.requestFocus();
                  },
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
                  focusNode: _confirmPasswordFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
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
                  onFieldSubmitted: (_) {
                    if (!authProvider.isLoading) {
                      _handleRegister();
                    }
                  },
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
                if (authProvider.error != null) ...[
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
                            authProvider.error!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      authProvider.isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Зарегистрироваться'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Страница регистрации, которая извлекает invite код из URL
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  @override
  void initState() {
    super.initState();
    _extractInviteAndNavigate();
  }

  Future<void> _extractInviteAndNavigate() async {
    // Небольшая задержка для инициализации
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    // Проверяем invite код в сервисе (уже должен быть обработан через app_links)
    String? inviteCode = DeepLinkService.instance.pendingInviteCode;

    // Если invite код не найден, пытаемся получить из текущего URL
    if (inviteCode == null) {
      inviteCode = await DeepLinkService.instance.checkCurrentUrlForInvite();
      if (inviteCode != null) {
        DeepLinkService.instance.setInviteCode(inviteCode);
      }
    }

    // Перенаправляем на страницу авторизации с invite кодом
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AuthPage(inviteCode: inviteCode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
