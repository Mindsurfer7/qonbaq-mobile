import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/pending_confirmations_provider.dart';
import '../providers/profile_provider.dart';

/// Главная страница приложения
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        final theme = context.appTheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Qonbaq'),
            backgroundColor: theme.backgroundSecondary,
            foregroundColor: theme.textPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  // Очищаем провайдеры перед выходом
                  final pendingProvider = Provider.of<PendingConfirmationsProvider>(context, listen: false);
                  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
                  
                  pendingProvider.clear();
                  profileProvider.clear();
                  
                  authProvider.logout();
                  Navigator.of(context).pushReplacementNamed('/auth');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Вы вышли из системы')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child:
                user != null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Добро пожаловать, ${user.username}!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('ID', user.id),
                                _buildInfoRow('Email', user.email),
                                _buildInfoRow('Username', user.username),
                                _buildInfoRow(
                                  'Admin',
                                  user.isAdmin ? 'Да' : 'Нет',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                    : const CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
