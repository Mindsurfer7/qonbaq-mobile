import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/business.dart';
import '../../core/error/failures.dart';
import '../providers/department_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/project_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/business_selector_widget.dart';
import '../widgets/department_tree_graph.dart';
import 'create_department_dialog.dart';
import 'create_project_dialog.dart';
import 'edit_project_dialog.dart';
import 'edit_business_slug_dialog.dart';

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
                  // Секция настроек автоматического распределения
                  _buildAutoAssignSection(profileProvider, selectedBusiness.id),
                  // Разделитель
                  Container(
                    height: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  // Секция внешней ссылки для клиентов
                  _buildBusinessSlugSection(profileProvider, selectedBusiness),
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
            if (project.phone != null && project.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      project.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            if (project.workingHours != null && project.workingHours!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      project.workingHours!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
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
                if (value == 'edit') {
                  _showEditProjectDialog(
                    context,
                    project,
                    provider,
                    businessId,
                  );
                } else if (value == 'delete') {
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
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Редактировать'),
                    ],
                  ),
                ),
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
            (project.city != null || project.country != null) ||
            (project.phone != null && project.phone!.isNotEmpty) ||
            (project.workingHours != null && project.workingHours!.isNotEmpty),
      ),
    );
  }

  void _showEditProjectDialog(
    BuildContext context,
    Project project,
    ProjectProvider provider,
    String businessId,
  ) {
    showDialog(
      context: context,
      builder: (context) => EditProjectDialog(
        project: project,
        onProjectUpdated: () {
          provider.loadProjects(businessId);
        },
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

  Widget _buildAutoAssignSection(ProfileProvider profileProvider, String businessId) {
    final business = profileProvider.selectedBusiness;
    if (business == null) return const SizedBox.shrink();

    // Проверяем, является ли пользователь гендиректором
    // Используем AuthProvider для более надежной проверки
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return const SizedBox.shrink();

    final permission = user.getPermissionsForBusiness(businessId);
    final isGeneralDirector = permission?.isGeneralDirector ?? false;
    
    if (!isGeneralDirector) return const SizedBox.shrink();

    return _AutoAssignWidget(businessId: businessId);
  }

  Widget _buildBusinessSlugSection(ProfileProvider profileProvider, Business business) {
    // Проверяем, является ли пользователь гендиректором
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return const SizedBox.shrink();

    final permission = user.getPermissionsForBusiness(business.id);
    final isGeneralDirector = permission?.isGeneralDirector ?? false;
    
    if (!isGeneralDirector) return const SizedBox.shrink();

    final slug = business.slug;
    final linkText = slug != null && slug.isNotEmpty
        ? 'qonbaq.com/business/$slug'
        : 'qonbaq.com/business/slug';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Внешняя ссылка для клиентов',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        linkText,
                        style: TextStyle(
                          fontSize: 14,
                          color: slug != null && slug.isNotEmpty
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showEditSlugDialog(context, business),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Изменить'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              if (slug == null || slug.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Пример того, как будет выглядеть ссылка',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSlugDialog(BuildContext context, Business business) {
    showDialog(
      context: context,
      builder: (context) => EditBusinessSlugDialog(business: business),
    );
  }
}

/// Виджет для управления автоматическим распределением сотрудников
class _AutoAssignWidget extends StatefulWidget {
  final String businessId;

  const _AutoAssignWidget({required this.businessId});

  @override
  State<_AutoAssignWidget> createState() => _AutoAssignWidgetState();
}

class _AutoAssignWidgetState extends State<_AutoAssignWidget> {
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        final currentBusiness = provider.selectedBusiness;
        if (currentBusiness == null || currentBusiness.id != widget.businessId) {
          return const SizedBox.shrink();
        }

        final autoAssign = currentBusiness.autoAssignDepartments;

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Автоматическое распределение сотрудников',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Автоматически распределять сотрудников по департаментам при назначении роли',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isUpdating)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        Switch(
                          value: autoAssign,
                          onChanged: (value) async {
                            setState(() {
                              _isUpdating = true;
                              _errorMessage = null;
                            });

                            try {
                              final updatedBusiness = Business(
                                id: currentBusiness.id,
                                name: currentBusiness.name,
                                description: currentBusiness.description,
                                position: currentBusiness.position,
                                orgPosition: currentBusiness.orgPosition,
                                department: currentBusiness.department,
                                hireDate: currentBusiness.hireDate,
                                createdAt: currentBusiness.createdAt,
                                type: currentBusiness.type,
                                autoAssignDepartments: value,
                                slug: currentBusiness.slug,
                              );

                              final result = await provider.updateBusinessCall(
                                currentBusiness.id,
                                updatedBusiness,
                              );

                              result.fold(
                                (failure) {
                                  setState(() {
                                    _errorMessage = failure is ServerFailure
                                        ? failure.message
                                        : 'Ошибка при обновлении настроек';
                                    _isUpdating = false;
                                  });
                                },
                                (updated) {
                                  setState(() {
                                    _isUpdating = false;
                                    _errorMessage = null;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value
                                              ? 'Автоматическое распределение включено'
                                              : 'Автоматическое распределение отключено',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              );
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Ошибка: $e';
                                _isUpdating = false;
                              });
                            }
                          },
                        ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

