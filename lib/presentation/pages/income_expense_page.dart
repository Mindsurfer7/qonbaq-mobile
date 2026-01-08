import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/project_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/financial_provider.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/account.dart';

/// Модель для моковых данных финансов проекта
class ProjectFinanceMock {
  final double income;
  final double expense;
  final double transit;
  final Map<String, double> analytics;

  ProjectFinanceMock({
    required this.income,
    required this.expense,
    required this.transit,
    required this.analytics,
  });
}

/// Страница доходов и расходов
class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  // Моковые данные для разных проектов
  final Map<String, ProjectFinanceMock> _mockData = {
    '1': ProjectFinanceMock(
      income: 1500000,
      expense: 800000,
      transit: 200000,
      analytics: {'Рентабельность': 46.6, 'Маржа': 35.0, 'ROI': 12.5},
    ),
    '2': ProjectFinanceMock(
      income: 2800000,
      expense: 2100000,
      transit: 50000,
      analytics: {'Рентабельность': 25.0, 'Маржа': 18.0, 'ROI': 8.2},
    ),
    '3': ProjectFinanceMock(
      income: 500000,
      expense: 450000,
      transit: 0,
      analytics: {'Рентабельность': 10.0, 'Маржа': 5.0, 'ROI': 2.1},
    ),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final projectProvider = Provider.of<ProjectProvider>(context, listen: false);
    
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId != null) {
      projectProvider.loadProjects(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доходы - Расходы'),
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
      body: Consumer3<ProjectProvider, ProfileProvider, FinancialProvider>(
        builder: (context, projectProvider, profileProvider, financialProvider, child) {
          final projects = projectProvider.projects ?? _getFallbackProjects();
          final businessId = profileProvider.selectedBusiness?.id ?? '';
          
          return Column(
            children: [
              // Выбор проекта и счета (50/50)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Селектор проекта
                    Expanded(
                      child: DropdownButtonFormField<Project>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Проект',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: financialProvider.selectedProject,
                        items: projects.map((project) {
                          return DropdownMenuItem(
                            value: project,
                            child: Text(
                              project.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          financialProvider.setSelectedProject(value, businessId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Селектор счета
                    Expanded(
                      child: DropdownButtonFormField<Account>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Счет',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        value: financialProvider.selectedAccount,
                        items: financialProvider.accounts.map((account) {
                          return DropdownMenuItem(
                            value: account,
                            child: Text(
                              account.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: financialProvider.selectedProject == null 
                          ? null 
                          : (value) {
                              financialProvider.setSelectedAccount(value);
                            },
                      ),
                    ),
                  ],
                ),
              ),
              
              if (financialProvider.selectedProject != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildEisenhowerQuadrant(
                          'Приход',
                          '${_mockData[financialProvider.selectedProject!.id]?.income.toStringAsFixed(0) ?? _mockData['1']!.income.toStringAsFixed(0)} ₽',
                          Icons.trending_up,
                          Colors.green,
                        ),
                        _buildEisenhowerQuadrant(
                          'Расход',
                          '${_mockData[financialProvider.selectedProject!.id]?.expense.toStringAsFixed(0) ?? _mockData['1']!.expense.toStringAsFixed(0)} ₽',
                          Icons.trending_down,
                          Colors.red,
                        ),
                        _buildEisenhowerQuadrant(
                          'Транзит',
                          '${_mockData[financialProvider.selectedProject!.id]?.transit.toStringAsFixed(0) ?? _mockData['1']!.transit.toStringAsFixed(0)} ₽',
                          Icons.swap_horiz,
                          Colors.orange,
                        ),
                        _buildAnalyticsQuadrant(financialProvider.selectedProject!.id),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text('Пожалуйста, выберите проект для просмотра данных'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Квадрант в стиле матрицы Эйзенхауэра
  Widget _buildEisenhowerQuadrant(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      color: color.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Квадрант аналитики
  Widget _buildAnalyticsQuadrant(String projectId) {
    final data = _mockData[projectId] ?? _mockData['1']!;
    final firstAnalytic = data.analytics.entries.first;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1),
      ),
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, color: Colors.blue, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Аналитика',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${firstAnalytic.key}: ${firstAnalytic.value}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Нажми для деталей',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Фолбек проекты, если список пуст
  List<Project> _getFallbackProjects() {
    return [
      Project(
        id: '1',
        name: 'Проект Альфа',
        businessId: 'mock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Project(
        id: '2',
        name: 'Проект Бета',
        businessId: 'mock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Project(
        id: '3',
        name: 'ЖК Парковый',
        businessId: 'mock',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}











