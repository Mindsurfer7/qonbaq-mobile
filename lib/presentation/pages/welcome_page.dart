import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/guest_uuid_storage.dart';

/// Страница приветствия с автоматическим гостевым логином
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _performGuestLogin();
  }

  Future<void> _performGuestLogin() async {
    try {
      // Получаем или генерируем guest UUID
      String? guestUuid = await GuestUuidStorage.getGuestUuid();
      if (guestUuid == null || guestUuid.isEmpty) {
        guestUuid = const Uuid().v4();
        await GuestUuidStorage.saveGuestUuid(guestUuid);
      }

      if (!mounted) return;

      // Выполняем гостевой логин
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.guestLogin(guestUuid: guestUuid);

      if (!mounted) return;

      if (success) {
        // Перенаправляем на страницу выбора workspace
        context.go('/workspace-selector');
      } else {
        setState(() {
          _isLoading = false;
          _error = authProvider.error ?? 'Ошибка входа в гостевой режим';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'Подключение к демо-версии...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ошибка подключения',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _performGuestLogin();
                          },
                          child: const Text('Попробовать снова'),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
