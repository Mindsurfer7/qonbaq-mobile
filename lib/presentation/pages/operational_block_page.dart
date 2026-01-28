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
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // Левый верхний: CRM + Управление услугами
          _buildCrmBlock(context),
          // Правый верхний: Задачи
          _buildTasksBlock(context),
          // Левый нижний: Бизнес-процессы
          _buildBusinessProcessesBlock(context),
          // Правый нижний: ERP
          _buildErpBlock(context),
        ],
      ),
    );
  }

  /// Левый верхний блок: CRM + Управление услугами
  Widget _buildCrmBlock(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'CRM',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallButton(
                      context,
                      'CRM',
                      Icons.people,
                      Colors.blue,
                      '/business/operational/crm',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallButton(
                      context,
                      'Управление услугами',
                      Icons.room_service,
                      Colors.blue,
                      '/business/operational/services-admin',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Правый верхний блок: Задачи
  Widget _buildTasksBlock(BuildContext context) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/tasks');
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
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Задачи',
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

  /// Левый нижний блок: Бизнес-процессы
  Widget _buildBusinessProcessesBlock(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed('/business/operational/business_processes');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings,
                size: 32,
                color: Colors.purple.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Бизнес-процессы',
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

  /// Правый нижний блок: ERP
  Widget _buildErpBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'ERP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSmallButton(
                      context,
                      'Строительство',
                      Icons.build,
                      Colors.green,
                      '/business/operational/construction',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallButton(
                      context,
                      'Торговля',
                      Icons.shopping_cart,
                      Colors.green,
                      '/business/operational/trade',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallButton(
                      context,
                      'Логистика и складской учёт',
                      Icons.local_shipping,
                      Colors.green,
                      '/business/operational/logistics',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallButton(
                      context,
                      'Сфера услуг',
                      Icons.room_service,
                      Colors.green,
                      '/business/operational/services',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Маленькая кнопка для блоков с несколькими элементами
  Widget _buildSmallButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}









