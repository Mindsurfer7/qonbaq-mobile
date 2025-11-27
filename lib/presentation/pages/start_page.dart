import 'package:flutter/material.dart';

/// Стартовая страница приложения
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QonbaQ Business Application')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'QonbaQ',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/business');
              },
              child: const Text('Войти в систему'),
            ),
            const SizedBox(height: 32),
            const Text('Этапы разработки приложения:'),
            const SizedBox(height: 16),
            _buildStage('Business Application', 0.8),
            _buildStage('Family Application', 0.1),
            _buildStage('Interaction with public organizations', 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(String name, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(name), LinearProgressIndicator(value: progress)],
      ),
    );
  }
}


