import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/token_storage.dart';
import '../../core/utils/deep_link_service.dart';
import '../../core/utils/workspace_storage.dart';
import '../../presentation/providers/auth_provider.dart';

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
    // Используем addPostFrameCallback для доступа к context после построения виджета
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  /// Проверка статуса аутентификации при старте
  Future<void> _checkAuthStatus() async {
    // Небольшая задержка для инициализации
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    final tokenStorage = TokenStorage.instance;
    
    // Если есть токены, пытаемся их валидировать и обновить
    if (tokenStorage.hasAccessToken() && tokenStorage.hasRefreshToken()) {
      final authProvider = context.read<AuthProvider>();
      final isValid = await authProvider.validateAndRefreshToken();
      
      if (!mounted) return;
      
      if (isValid) {
        // Токен валиден, проверяем есть ли сохраненный workspace
        final hasWorkspace = await WorkspaceStorage.hasSelectedWorkspace();
        if (!mounted) return;
        
        if (hasWorkspace) {
          // Если есть сохраненный workspace, переходим на главную страницу
          // BusinessMainPage сам загрузит workspace из ProfileProvider
          context.go('/business');
        } else {
          // Если нет сохраненного workspace, переходим на выбор workspace
          context.go('/workspace-selector');
        }
      } else {
        // Токен невалиден, перенаправляем на страницу логина
        context.go('/auth');
      }
    } else {
      // Если токенов нет, проверяем наличие кода приглашения
      final inviteCode = DeepLinkService.instance.pendingInviteCode;
      if (mounted) {
        if (inviteCode != null) {
          // Если есть код приглашения, открываем страницу авторизации
          // inviteCode передается через state в app_router
          context.go('/auth');
        } else {
          // Если кода приглашения нет, перенаправляем на страницу логина
          context.go('/auth');
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


