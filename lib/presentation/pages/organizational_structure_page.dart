import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/project.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/department_tree_graph.dart';
import 'create_department_dialog.dart';
import 'create_project_dialog.dart';

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
      final projectProvider =
          Provider.of<ProjectProvider>(context, listen: false);

      if (profileProvider.selectedBusiness != null) {
        final businessId = profileProvider.selectedBusiness!.id;
        projectProvider.loadProjects(businessId);
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
      body: Consumer3<ProfileProvider, DepartmentProvider, ProjectProvider>(
        builder: (context, profileProvider, departmentProvider, projectProvider, child) {
          final selectedBusiness = profileProvider.selectedBusiness;

          if (selectedBusiness == null) {
            return const Center(
              child: Text('Выберите компанию'),
            );
          }

          // Загружаем данные при изменении выбранной компании
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (departmentProvider.departments == null ||
                (departmentProvider.departments != null &&
                    departmentProvider.departments!.isNotEmpty &&
                    departmentProvider.departments!.first.businessId !=
                        selectedBusiness.id)) {
              projectProvider.loadProjects(selectedBusiness.id);
              departmentProvider.loadDepartments(selectedBusiness.id);
              departmentProvider.loadDepartmentsTree(selectedBusiness.id);
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              await projectProvider.loadProjects(selectedBusiness.id);
              await departmentProvider.loadDepartments(selectedBusiness.id);
              await departmentProvider.loadDepartmentsTree(selectedBusiness.id);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Виджет выбора компании
                  const BusinessSelectorWidget(compact: true),
                  // Секция проектов
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Проекты',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        FloatingActionButton.small(
                          onPressed: () => _showCreateProjectDialog(
                            context,
                            selectedBusiness.id,
                            projectProvider,
                          ),
                          child: const Icon(Icons.add),
                          tooltip: 'Создать проект',
                          heroTag: 'create_project',
                        ),
                      ],
                    ),
                  ),
                  // Список проектов (без внутреннего скролла — скроллится вся страница)
                  _buildProjectsList(
                    projectProvider,
                    selectedBusiness.id,
                  ),
                  // Разделитель
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Секция подразделений
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
                          heroTag: 'create_department',
                        ),
                      ],
                    ),
                  ),
                  // Список департаментов (без внутреннего скролла — скроллится вся страница)
                  _buildDepartmentsList(
                    departmentProvider,
                    selectedBusiness.id,
                  ),
                  // Разделитель
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Секция распределения ролей
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed('/roles-assignment');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.assignment_ind,
                              color: Theme.of(context).primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Распределение ролей',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Назначение ролей сотрудникам',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Разделитель
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Заголовок графа
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Граф организационной структуры',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Граф подразделений (без ограничений по высоте)
                  _buildDepartmentsTree(
                    departmentProvider,
                    selectedBusiness.id,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
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
        ),
      );
    }

    if (provider.departments == null || provider.departments!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.business,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Нет подразделений',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первое подразделение',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (final department in provider.departments!)
            _buildDepartmentCard(department, provider, businessId),
        ],
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && provider.departmentsTree == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
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
        ),
      );
    }

    final tree = provider.departmentsTree ?? [];
    if (tree.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
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

  void _showCreateProjectDialog(
    BuildContext context,
    String businessId,
    ProjectProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(
        businessId: businessId,
        onProjectCreated: () {
          provider.loadProjects(businessId);
        },
      ),
    );
  }

  Widget _buildProjectsList(
    ProjectProvider provider,
    String businessId,
  ) {
    if (provider.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                provider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.loadProjects(businessId),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.projects == null || provider.projects!.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.folder,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'Нет проектов',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Создайте первый проект',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          for (final project in provider.projects!)
            _buildProjectCard(project, provider, businessId),
        ],
      ),
    );
  }

  Widget _buildProjectCard(
    Project project,
    ProjectProvider provider,
    String businessId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          project.isActive ? Icons.folder : Icons.folder_off,
          size: 32,
          color: project.isActive ? Colors.blue : Colors.grey,
        ),
        title: Text(
          project.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            decoration: project.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null && project.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  project.description!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (project.city != null || project.country != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  [
                    if (project.city != null) project.city,
                    if (project.country != null) project.country,
                  ].join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          // TODO: Навигация на страницу деталей проекта
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
                  _showDeleteProjectConfirmation(
                    context,
                    project,
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
        isThreeLine: (project.description != null &&
                project.description!.isNotEmpty) ||
            (project.city != null || project.country != null),
      ),
    );
  }

  void _showDeleteProjectConfirmation(
    BuildContext context,
    Project project,
    ProjectProvider provider,
    String businessId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление проекта'),
        content: Text(
          'Вы уверены, что хотите удалить проект "${project.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await provider.removeProject(project.id);
              if (success && context.mounted) {
                provider.loadProjects(businessId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Проект удален'),
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

