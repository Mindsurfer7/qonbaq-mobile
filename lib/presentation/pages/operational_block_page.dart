import 'package:flutter/material.dart';

/// Страница операционного блока
class OperationalBlockPage extends StatelessWidget {
  const OperationalBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Операционный блок'),
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
          _buildSectionCard(
            context,
            'CRM',
            '/business/operational/crm',
            Icons.people,
          ),
          _buildSectionCard(
            context,
            'Задачи',
            '/business/operational/tasks',
            Icons.task,
          ),
          _buildSectionCard(
            context,
            'Бизнес-процессы',
            '/business/operational/business_processes',
            Icons.settings,
          ),
          _buildSectionCard(
            context,
            'Строительство',
            '/business/operational/construction',
            Icons.build,
          ),
          _buildSectionCard(
            context,
            'Монитор панель и админ',
            '/business/operational/monitor_panel',
            Icons.monitor,
          ),
          _buildSectionCard(
            context,
            'Управление услугами',
            '/business/operational/services-admin',
            Icons.room_service,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    String route,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).pushNamed(route),
      ),
    );
  }
}









