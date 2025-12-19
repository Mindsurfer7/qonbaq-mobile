import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/department_tree_graph.dart';
import 'create_department_dialog.dart';

/// Страница организационной структуры
class OrganizationalStructurePage extends StatefulWidget {
  const OrganizationalStructurePage({super.key});

  @override
  State<OrganizationalStructurePage> createState() =>
      _OrganizationalStructurePageState();
}

class _OrganizationalStructurePageState
    extends State<OrganizationalStructurePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider =
          Provider.of<ProfileProvider>(context, listen: false);
      final departmentProvider =
          Provider.of<DepartmentProvider>(context, listen: false);

      if (profileProvider.selectedBusiness != null) {
        final businessId = profileProvider.selectedBusiness!.id;
        departmentProvider.loadDepartments(businessId);
        departmentProvider.loadDepartmentsTree(businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Организационная структура'),
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
      body: Consumer2<ProfileProvider, DepartmentProvider>(
        builder: (context, profileProvider, departmentProvider, child) {
          final selectedBusiness = profileProvider.selectedBusiness;

          if (selectedBusiness == null) {
            return const Center(
              child: Text('Выберите компанию'),
            );
          }

          // Загружаем департаменты при изменении выбранной компании
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (departmentProvider.departments == null ||
                (departmentProvider.departments != null &&
                    departmentProvider.departments!.isNotEmpty &&
                    departmentProvider.departments!.first.businessId !=
                        selectedBusiness.id)) {
              departmentProvider.loadDepartments(selectedBusiness.id);
              departmentProvider.loadDepartmentsTree(selectedBusiness.id);
            }
          });

          return Column(
            children: [
              // Виджет выбора компании
              const BusinessSelectorWidget(compact: true),
              // Кнопка создания департамента
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Подразделения',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FloatingActionButton.small(
                      onPressed: () => _showCreateDepartmentDialog(
                        context,
                        selectedBusiness.id,
                        departmentProvider,
                      ),
                      child: const Icon(Icons.add),
                      tooltip: 'Создать подразделение',
                    ),
                  ],
                ),
              ),
              // Список департаментов (сверху)
              Expanded(
                flex: 1,
                child: _buildDepartmentsList(
                  departmentProvider,
                  selectedBusiness.id,
                ),
              ),
              // Разделитель
              Container(
                height: 1,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
              // Заголовок графа
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text(
                      'Граф организационной структуры',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Граф подразделений (снизу)
              Expanded(
                flex: 1,
                child: _buildDepartmentsTree(
                  departmentProvider,
                  selectedBusiness.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDepartmentsList(
    DepartmentProvider provider,
    String businessId,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadDepartments(businessId),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (provider.departments == null || provider.departments!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.business,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Нет подразделений',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте первое подразделение',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadDepartments(businessId);
        await provider.loadDepartmentsTree(businessId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: provider.departments!.length,
        itemBuilder: (context, index) {
          final department = provider.departments![index];
          return _buildDepartmentCard(department, provider, businessId);
        },
      ),
    );
  }

  Widget _buildDepartmentCard(
    Department department,
    DepartmentProvider provider,
    String businessId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.business, size: 32),
        title: Text(
          department.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: department.description != null &&
                department.description!.isNotEmpty
            ? Text(
                department.description!,
                style: const TextStyle(fontSize: 14),
              )
            : null,
        onTap: () {
          Navigator.of(context).pushNamed(
            '/department_detail',
            arguments: department.id,
          );
        },
        trailing: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final isGeneralDirector =
                profileProvider.profile?.orgStructure.isGeneralDirector ?? false;
            
            if (!isGeneralDirector) {
              return const SizedBox.shrink();
            }

            return PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(
                    context,
                    department,
                    provider,
                    businessId,
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        isThreeLine: department.description != null &&
            department.description!.isNotEmpty,
      ),
    );
  }

  void _showCreateDepartmentDialog(
    BuildContext context,
    String businessId,
    DepartmentProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => CreateDepartmentDialog(
        businessId: businessId,
        // parentId не передается - создается корневое подразделение
        onDepartmentCreated: () {
          provider.loadDepartments(businessId);
          provider.loadDepartmentsTree(businessId);
        },
      ),
    );
  }

  Widget _buildDepartmentsTree(
    DepartmentProvider provider,
    String businessId,
  ) {
    if (provider.isLoading && provider.departmentsTree == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.departmentsTree == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.loadDepartmentsTree(businessId);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    final tree = provider.departmentsTree ?? [];
    if (tree.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Нет подразделений для отображения',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessName = profileProvider.selectedBusiness?.name;

    return DepartmentTreeGraph(
      departments: tree,
      businessName: businessName,
      onDepartmentTap: (departmentId) {
        Navigator.of(context).pushNamed(
          '/department_detail',
          arguments: departmentId,
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Department department,
    DepartmentProvider provider,
    String businessId,
  ) {
    // Проверяем, является ли пользователь гендиректором
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final isGeneralDirector = profileProvider.profile?.orgStructure.isGeneralDirector ?? false;

    if (!isGeneralDirector) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Только генеральный директор может удалять подразделения'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление подразделения'),
        content: Text(
          'Вы уверены, что хотите удалить подразделение "${department.name}"? '
          'Все сотрудники подразделения получат статус pending assignment, '
          'а дочерние подразделения станут корневыми.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.removeDepartment(department.id);
              if (success && context.mounted) {
                // Перезагружаем данные
                provider.loadDepartments(businessId);
                provider.loadDepartmentsTree(businessId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Подразделение удалено'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.error ?? 'Ошибка при удалении',
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

