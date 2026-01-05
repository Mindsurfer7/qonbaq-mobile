import 'package:flutter/material.dart';

/// Страница монитор панели и админа
class MonitorPanelPage extends StatelessWidget {
  const MonitorPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Монитор панель и админ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: const Center(child: Text('Монитор панель и админ')),
    );
  }
}









