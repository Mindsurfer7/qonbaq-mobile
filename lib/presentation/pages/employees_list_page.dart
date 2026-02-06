import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_detail_page.dart';

/// Страница со списком сотрудников компании для начала чата
class EmployeesListPage extends StatefulWidget {
  const EmployeesListPage({super.key});

  @override
  State<EmployeesListPage> createState() => _EmployeesListPageState();
}

class _EmployeesListPageState extends State<EmployeesListPage> {
  List<Employee>? _employees;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    if (selectedBusiness == null) {
      setState(() {
        _error = 'Компания не выбрана';
        _isLoading = false;
      });
      return;
    }

    // Проверяем кэш
    final cachedEmployees = profileProvider.getEmployeesForBusiness(
      selectedBusiness.id,
    );

    if (cachedEmployees != null && cachedEmployees.isNotEmpty) {
      setState(() {
        _employees = cachedEmployees;
        _isLoading = false;
      });
      return;
    }

    // Загружаем сотрудников
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final result = await userRepository.getBusinessEmployees(selectedBusiness.id);

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message.isNotEmpty
              ? failure.message
              : 'Ошибка при загрузке сотрудников';
          _isLoading = false;
        });
      },
      (employees) {
        // Кэшируем сотрудников
        profileProvider.cacheEmployees(selectedBusiness.id, employees);

        setState(() {
          _employees = employees;
          _isLoading = false;
        });
      },
    );
  }

  void _openChatWithEmployee(Employee employee) {
    final chatRepository = Provider.of<ChatRepository>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Не открываем чат с самим собой
    final currentUserId = authProvider.user?.id;
    if (currentUserId != null && currentUserId == employee.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нельзя начать чат с самим собой')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          interlocutorName: employee.fullName,
          interlocutorId: employee.id,
          chatRepository: chatRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сотрудники'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadEmployees,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _employees == null || _employees!.isEmpty
                  ? Center(
                      child: Text(
                        'Нет доступных сотрудников',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadEmployees,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _employees!.length,
                        itemBuilder: (context, index) {
                          final employee = _employees![index];
                          return _buildEmployeeCard(employee);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmployeeCard(Employee employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            employee.fullName.isNotEmpty
                ? employee.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          employee.fullName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.position != null && employee.position!.isNotEmpty)
              Text(
                employee.position!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            if (employee.department != null && employee.department!.isNotEmpty)
              Text(
                employee.department!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            if (employee.email != null && employee.email!.isNotEmpty)
              Text(
                employee.email!,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chat_bubble_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => _openChatWithEmployee(employee),
      ),
    );
  }
}

