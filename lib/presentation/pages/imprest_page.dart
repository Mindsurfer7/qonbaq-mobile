import 'package:flutter/material.dart';

/// Страница подотчетных сумм
class ImprestPage extends StatelessWidget {
  const ImprestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Подотчетные суммы'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Основное средство 1'),
              subtitle: const Text('Пример карточки основного средства'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed('/business/admin/imprest/assets_card');
              },
            ),
          ),
        ],
      ),
    );
  }
}









