import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/roles_provider.dart';
import '../../domain/entities/employment_with_role.dart';

/// Страница распределения ролей
class RolesAssignmentPage extends StatefulWidget {
  const RolesAssignmentPage({super.key});

  @override
  State<RolesAssignmentPage> createState() => _RolesAssignmentPageState();
}

class _RolesAssignmentPageState extends State<RolesAssignmentPage> {
  final Map<String, String?> _roleChanges = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final rolesProvider = Provider.of<RolesProvider>(context, listen: false);
      final selectedBusiness = profileProvider.selectedBusiness;

      if (selectedBusiness != null) {
        rolesProvider.loadEmployments(selectedBusiness.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Распределение ролей'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Выберите компанию')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Распределение ролей'),
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
      body: Consumer<RolesProvider>(
        builder: (context, rolesProvider, child) {
          if (rolesProvider.isLoading && rolesProvider.employments == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (rolesProvider.error != null &&
              rolesProvider.employments == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rolesProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed:
                        () =>
                            rolesProvider.loadEmployments(selectedBusiness.id),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final employments = rolesProvider.employments;
          if (employments == null || employments.isEmpty) {
            return const Center(child: Text('Нет сотрудников для отображения'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: employments.length,
                  itemBuilder: (context, index) {
                    final employment = employments[index];
                    return _EmployeeRoleTile(
                      employment: employment,
                      onRoleChanged: (roleCode) {
                        setState(() {
                          if (roleCode == employment.roleCode) {
                            _roleChanges.remove(employment.id);
                          } else {
                            _roleChanges[employment.id] = roleCode;
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              if (_roleChanges.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Изменения: ${_roleChanges.length} сотрудник${_roleChanges.length == 1
                              ? ''
                              : _roleChanges.length < 5
                              ? 'а'
                              : 'ов'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton(
                        onPressed:
                            rolesProvider.isLoading
                                ? null
                                : () async {
                                  final success = await rolesProvider
                                      .updateRoles(_roleChanges);
                                  if (success && mounted) {
                                    setState(() {
                                      _roleChanges.clear();
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Роли успешно обновлены',
                                                ),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          }
                                        });
                                  }
                                },
                        child:
                            rolesProvider.isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Сохранить'),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Виджет для отображения сотрудника с селектором роли
class _EmployeeRoleTile extends StatelessWidget {
  final EmploymentWithRole employment;
  final ValueChanged<String?> onRoleChanged;

  const _EmployeeRoleTile({
    required this.employment,
    required this.onRoleChanged,
  });

  static const Map<String, String> _roleNames = {
    'ACCOUNTANT': 'Бухгалтер',
    'LAWYER': 'Юрист',
    'SALES_MANAGER': 'Менеджер продаж',
    'PURCHASE_MANAGER': 'Менеджер закупа',
    'SECRETARY': 'Секретарь',
    'MARKETER': 'Маркетолог',
    'FINANCE_MANAGER': 'Менеджер по финансам',
    'LOGISTICIAN': 'Логист',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Аватар сотрудника
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withAlpha(25),
              child: Text(
                employment.user.firstName?.isNotEmpty == true
                    ? employment.user.firstName![0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Информация о сотруднике
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employment.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (employment.position != null)
                    Text(
                      employment.position!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  Text(
                    employment.user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Селектор роли
            Flexible(
              child: DropdownButtonFormField<String?>(
                value: employment.roleCode,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                hint: const Text('Роль', overflow: TextOverflow.ellipsis),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Без роли', overflow: TextOverflow.ellipsis),
                  ),
                  ..._roleNames.entries.map(
                    (entry) => DropdownMenuItem<String?>(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: onRoleChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
