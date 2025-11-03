import 'package:flutter/material.dart';

/// Страница реквизитов клиента
class ClientRequisitesPage extends StatelessWidget {
  const ClientRequisitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Реквизиты клиента'),
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
      body: const Center(child: Text('Реквизиты клиента (Компания)')),
    );
  }
}
