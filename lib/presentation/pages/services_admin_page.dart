import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/employee.dart';
import '../../domain/usecases/get_business_services.dart';
import '../../domain/usecases/delete_service.dart';
import '../../domain/usecases/delete_service_assignment.dart';
import '../../domain/repositories/service_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../providers/profile_provider.dart';
import 'create_service_dialog.dart';
import 'edit_service_dialog.dart';
import 'assign_employee_to_service_dialog.dart';

/// Админ-панель для управления услугами
class ServicesAdminPage extends StatefulWidget {
  const ServicesAdminPage({super.key});

  @override
  State<ServicesAdminPage> createState() => _ServicesAdminPageState();
}

class _ServicesAdminPageState extends State<ServicesAdminPage> {
  List<Service> _services = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool showLoading = true}) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _error = 'Компания не выбрана';
      });
      return;
    }

    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    // Загружаем только услуги
    final serviceRepository = Provider.of<ServiceRepository>(
      context,
      listen: false,
    );
    final getServices = GetBusinessServices(serviceRepository);
    final servicesResult = await getServices.call(
      GetBusinessServicesParams(businessId: selectedBusiness.id),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      servicesResult.fold((failure) => _error = failure.message, (services) {
        _services = services;
        _error = null;
      });
    });
  }

  Future<void> _createService() async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) return;

    // Загружаем сотрудников только при открытии диалога
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final employeesResult = await userRepository.getBusinessEmployees(
      selectedBusiness.id,
    );

    if (!mounted) return;

    final employees = employeesResult.fold(
      (failure) => <Employee>[],
      (employees) => employees,
    );

    final result = await showDialog<Service>(
      context: context,
      builder:
          (context) => CreateServiceDialog(
            businessId: selectedBusiness.id,
            employees: employees,
          ),
    );

    if (result != null && mounted) {
      await _loadData(showLoading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Услуга успешно создана'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _editService(Service service) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) return;

    // Загружаем сотрудников только при открытии диалога
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final employeesResult = await userRepository.getBusinessEmployees(
      selectedBusiness.id,
    );

    if (!mounted) return;

    final employees = employeesResult.fold(
      (failure) => <Employee>[],
      (employees) => employees,
    );

    final result = await showDialog<Service>(
      context: context,
      builder:
          (context) =>
              EditServiceDialog(service: service, employees: employees),
    );

    if (result != null && mounted) {
      await _loadData(showLoading: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Услуга успешно обновлена'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteService(Service service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить услугу?'),
            content: Text(
              'Вы уверены, что хотите удалить услугу "${service.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final serviceRepository = Provider.of<ServiceRepository>(
        context,
        listen: false,
      );
      final deleteService = DeleteService(serviceRepository);
      final result = await deleteService.call(service.id);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: ${failure.message}')));
        },
        (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Услуга удалена')));
          _loadData(showLoading: false);
        },
      );
    }
  }

  Future<void> _assignEmployee(Service service) async {
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) return;

    // Загружаем сотрудников только при открытии диалога
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final employeesResult = await userRepository.getBusinessEmployees(
      selectedBusiness.id,
    );

    if (!mounted) return;

    final employees = employeesResult.fold(
      (failure) => <Employee>[],
      (employees) => employees,
    );

    // Кэшируем сотрудников для ProfileProvider
    profileProvider.cacheEmployees(selectedBusiness.id, employees);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AssignEmployeeToServiceDialog(service: service),
    );

    if (result == true && mounted) {
      await _loadData(showLoading: false);
    }
  }

  Future<void> _deleteAssignment(ServiceAssignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить назначение?'),
            content: const Text(
              'Вы уверены, что хотите удалить это назначение?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final serviceRepository = Provider.of<ServiceRepository>(
        context,
        listen: false,
      );
      final deleteAssignment = DeleteServiceAssignment(serviceRepository);
      final result = await deleteAssignment.call(assignment.id);

      result.fold(
        (failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка: ${failure.message}')));
        },
        (_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Назначение удалено')));
          _loadData(showLoading: false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление услугами'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadData(showLoading: false),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка: $_error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              )
              : _buildServicesTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createService,
        child: const Icon(Icons.add),
        tooltip: 'Создать услугу',
      ),
    );
  }

  Widget _buildServicesTab() {
    // Разделяем услуги на активные и неактивные
    final activeServices = _services.where((s) => s.isActive).toList();
    final inactiveServices = _services.where((s) => !s.isActive).toList();

    if (_services.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadData(showLoading: false),
        child: ListView(
          children: const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Нет услуг. Создайте первую услугу.'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(showLoading: false),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // Активные услуги
          if (activeServices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Активные',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...activeServices.map((service) => _buildServiceCard(service)),
          ],
          // Неактивные услуги
          if (inactiveServices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                top: 24,
                bottom: 12,
              ),
              child: Text(
                'Неактивные',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...inactiveServices.map((service) => _buildServiceCard(service)),
          ],
        ],
      ),
    );
  }

  String _buildServiceSubtitle(Service service) {
    final parts = <String>[];

    // Тип услуги
    final typeLabel =
        service.type == ServiceType.personBased ? 'Услуга' : 'Ресурс';
    parts.add(typeLabel);

    // Для PERSON_BASED услуг показываем duration и price
    if (service.type == ServiceType.personBased) {
      if (service.duration != null) {
        parts.add('Длительность: ${service.duration} мин.');
      }
      if (service.price != null) {
        parts.add('Цена: ${service.price} ${service.currency ?? 'KZT'}');
      }
    }

    // Для RESOURCE_BASED услуг показываем capacity
    if (service.type == ServiceType.resourceBased && service.capacity != null) {
      parts.add('Вместимость: ${service.capacity}');
    }

    return parts.join(' | ');
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        leading: Icon(
          service.isActive ? Icons.check_circle : Icons.cancel,
          color: service.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(service.name),
        subtitle: Text(_buildServiceSubtitle(service)),
        trailing: SizedBox(
          width: 140,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    '/business/operational/services-admin/service-detail',
                    arguments: service,
                  );
                },
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                tooltip: 'Тайм-слоты',
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editService(service),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteService(service),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ),
        children: [
          if (service.description != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(service.description!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Назначенные сотрудники',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (service.type == ServiceType.personBased)
                  TextButton.icon(
                    onPressed: () => _assignEmployee(service),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Назначить'),
                  ),
              ],
            ),
          ),
          if (service.assignments != null &&
              service.assignments!.isNotEmpty) ...[
            ...service.assignments!.map((assignment) {
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(assignment.employee?.fullName ?? 'Неизвестно'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteAssignment(assignment),
                ),
              );
            }),
          ] else if (service.users != null && service.users!.isNotEmpty) ...[
            // Показываем users если нет assignments (для обратной совместимости)
            ...service.users!.map((user) {
              final fullName = [
                if (user.lastName != null) user.lastName,
                if (user.firstName != null) user.firstName,
              ].where((part) => part != null).join(' ');
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(fullName.isNotEmpty ? fullName : 'Неизвестно'),
                dense: true,
              );
            }),
          ] else ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Нет назначенных сотрудников',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
