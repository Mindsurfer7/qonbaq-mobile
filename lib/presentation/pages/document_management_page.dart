import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

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
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
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
                context.go(
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









