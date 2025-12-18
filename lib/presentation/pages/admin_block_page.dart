import 'package:flutter/material.dart';

/// Страница административно-хозяйственного блока
class AdminBlockPage extends StatelessWidget {
  const AdminBlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Административно-хозяйственный блок'),
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
            'Документооборот',
            '/business/admin/document_management',
            Icons.description,
          ),
          _buildSectionCard(
            context,
            'Подотчетные суммы',
            '/business/admin/imprest',
            Icons.account_balance_wallet,
          ),
          _buildSectionCard(
            context,
            'HR документы',
            '/business/admin/hr_documents',
            Icons.folder,
          ),
          _buildSectionCard(
            context,
            'График работы персонала',
            '/business/admin/staff_schedule',
            Icons.schedule,
          ),
          _buildSectionCard(
            context,
            'Табелирование',
            '/business/admin/timesheet',
            Icons.access_time,
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




