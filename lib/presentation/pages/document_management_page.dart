import 'package:flutter/material.dart';

/// Страница документооборота
class DocumentManagementPage extends StatelessWidget {
  const DocumentManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Документооборот'),
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
              title: const Text('Сотрудник 1'),
              subtitle: const Text('Пример карточки сотрудника'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pushNamed(
                  '/business/admin/document_management/employee_card',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
