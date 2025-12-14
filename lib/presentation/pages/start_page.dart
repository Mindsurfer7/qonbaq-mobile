import 'package:flutter/material.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/deep_link_service.dart';
import 'auth_page.dart';

/// Стартовая страница приложения
class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Проверка статуса аутентификации при старте
  Future<void> _checkAuthStatus() async {
    // Небольшая задержка для инициализации
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final tokenStorage = TokenStorage.instance;
    
    // Если есть токены, перенаправляем на главную страницу
    if (tokenStorage.hasAccessToken() && tokenStorage.hasRefreshToken()) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/business');
      }
    } else {
      // Если токенов нет, проверяем наличие кода приглашения
      final inviteCode = DeepLinkService.instance.pendingInviteCode;
      if (mounted) {
        if (inviteCode != null) {
          // Если есть код приглашения, открываем страницу регистрации с кодом
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => AuthPage(inviteCode: inviteCode),
            ),
          );
        } else {
          // Если кода приглашения нет, перенаправляем на страницу логина
          Navigator.of(context).pushReplacementNamed('/auth');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QonbaQ Business Application')),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


