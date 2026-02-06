import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

/// Страница карточки клиента
class ClientCardPage extends StatelessWidget {
  const ClientCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка клиента'),
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
          _buildSectionCard(
            context,
            'Реквизиты клиента (Компания)',
            '/business/operational/crm/clients_list/client_card/client_requisites',
            Icons.business,
          ),
          _buildSectionCard(
            context,
            'Карточка сделки по клиенту',
            '/business/operational/crm/clients_list/client_card/client_deal',
            Icons.handshake,
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
        onTap: () => context.go(route),
      ),
    );
  }
}









