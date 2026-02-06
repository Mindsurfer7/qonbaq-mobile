import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

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
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          // Левый верхний: Документооборот
          _buildDocumentManagementBlock(context),
          // Правый верхний: Подотчет
          _buildImprestBlock(context),
          // Левый нижний: Кадровые документы
          _buildHrDocumentsBlock(context),
          // Правый нижний: Согласование процессов АХО
          _buildApprovalProcessesBlock(context),
        ],
      ),
    );
  }

  /// Левый верхний блок: Документооборот
  Widget _buildDocumentManagementBlock(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          context.go('/business/admin/document_management');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description,
                size: 32,
                color: Colors.blue.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Документооборот',
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

  /// Правый верхний блок: Подотчет
  Widget _buildImprestBlock(BuildContext context) {
    return Card(
      color: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Подотчет',
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
                    _buildSmallImprestButton(
                      context,
                      'Подотчетные суммы',
                      Icons.account_balance_wallet,
                      Colors.green,
                      '/business/admin/imprest',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallImprestButton(
                      context,
                      'Основные средства',
                      Icons.build,
                      Colors.green,
                      '/business/admin/fixed_assets',
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

  /// Маленькая кнопка для подотчета
  Widget _buildSmallImprestButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => context.go(route),
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

  /// Левый нижний блок: Кадровые документы
  Widget _buildHrDocumentsBlock(BuildContext context) {
    return Card(
      color: Colors.purple.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Кадровые документы',
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
                    _buildSmallHrButton(
                      context,
                      'HR документы',
                      Icons.folder,
                      Colors.purple,
                      '/business/admin/hr_documents',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallHrButton(
                      context,
                      'График работы',
                      Icons.schedule,
                      Colors.purple,
                      '/business/admin/staff_schedule',
                    ),
                    const SizedBox(height: 8),
                    _buildSmallHrButton(
                      context,
                      'Табелирование',
                      Icons.access_time,
                      Colors.purple,
                      '/business/admin/timesheet',
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

  /// Маленькая кнопка для кадровых документов
  Widget _buildSmallHrButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
  ) {
    return InkWell(
      onTap: () => context.go(route),
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

  /// Правый нижний блок: Согласование процессов АХО
  Widget _buildApprovalProcessesBlock(BuildContext context) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: InkWell(
        onTap: () {
          // TODO: Добавить навигацию на страницу согласования процессов АХО
          // context.go('/business/admin/approvals');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Страница в разработке'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment,
                size: 32,
                color: Colors.orange.shade700,
              ),
              const SizedBox(height: 8),
              const Text(
                'Согласование процессов АХО',
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




