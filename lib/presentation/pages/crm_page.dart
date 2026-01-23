import 'package:flutter/material.dart';

/// Страница CRM
class CrmPage extends StatelessWidget {
  const CrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM'),
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
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // Левый верхний: Воронка продаж
          _buildSalesFunnelBlock(context),
          // Правый верхний: Воронка заказов
          _buildOrdersFunnelBlock(context),
          // Левый нижний: Задачи по клиентам
          _buildClientTasksBlock(context),
          // Правый нижний: Список клиентов
          _buildClientsListBlock(context),
        ],
      ),
    );
  }

  /// Левый верхний блок: Воронка продаж
  Widget _buildSalesFunnelBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/crm/sales_funnel');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.trending_down,
                size: 32,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Воронка продаж',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Правый верхний блок: Воронка заказов
  Widget _buildOrdersFunnelBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/crm/orders_funnel');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_cart,
                size: 32,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Воронка заказов',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Левый нижний блок: Задачи по клиентам
  Widget _buildClientTasksBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/crm/tasks_crm');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task,
                size: 32,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Задачи по клиентам',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Правый нижний блок: Список клиентов
  Widget _buildClientsListBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/crm/clients_list');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: 32,
                color: Colors.green.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Список клиентов',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}









