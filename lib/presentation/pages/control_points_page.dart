import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/control_point.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_control_points.dart';
import '../../core/error/failures.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

/// Страница контрольных точек
class ControlPointsPage extends StatefulWidget {
  const ControlPointsPage({super.key});

  @override
  State<ControlPointsPage> createState() => _ControlPointsPageState();
}

class _ControlPointsPageState extends State<ControlPointsPage> {
  List<ControlPoint> _controlPoints = [];
  bool _isLoading = false;
  String? _error;
  PaginationMeta? _meta;
  int _page = 1;
  static const int _pageLimit = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadControlPoints();
    });
  }

  Future<void> _loadControlPoints({bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;
    if (selectedBusiness == null) {
      setState(() {
        _error = 'Необходимо выбрать компанию';
      });
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final profile = profileProvider.profile;

    // Проверяем, является ли пользователь гендиректором
    final isGeneralDirector = currentUser?.isAdmin == true ||
        profile?.orgStructure.isGeneralDirector == true;

    setState(() {
      _isLoading = true;
      _error = null;
      if (refresh) {
        _page = 1;
        _controlPoints = [];
      }
    });

    final getControlPointsUseCase =
        Provider.of<GetControlPoints>(context, listen: false);

    print('Page: Calling useCase with params:');
    print('  businessId: ${selectedBusiness.id}');
    print('  isGeneralDirector: $isGeneralDirector');
    print('  showAll: ${isGeneralDirector ? true : null}');
    print('  assignedTo: ${isGeneralDirector ? null : currentUser?.id}');
    print('  page: $_page');
    print('  limit: $_pageLimit');
    
    final result = await getControlPointsUseCase.call(
      GetControlPointsParams(
        businessId: selectedBusiness.id,
        // Для гендиректора передаем showAll=true, чтобы получить все точки контроля бизнеса
        showAll: isGeneralDirector ? true : null,
        // Для обычных пользователей показываем только их точки контроля
        assignedTo: isGeneralDirector ? null : currentUser?.id,
        page: _page,
        limit: _pageLimit,
      ),
    );

    print('Page: UseCase returned result');
    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке точек контроля'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (paginatedResult) {
        // Отладочная информация
        print('ControlPoints loaded: ${paginatedResult.items.length} items');
        print('Meta: ${paginatedResult.meta?.total} total, page ${paginatedResult.meta?.page}');
        
        setState(() {
          _isLoading = false;
          if (refresh) {
            _controlPoints = paginatedResult.items;
          } else {
            _controlPoints.addAll(paginatedResult.items);
          }
          _meta = paginatedResult.meta;
        });
        
        // Дополнительная отладочная информация
        print('ControlPoints in state: ${_controlPoints.length} items');
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  String _getFrequencyText(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Ежедневно';
      case RecurrenceFrequency.weekly:
        return 'Еженедельно';
      case RecurrenceFrequency.monthly:
        return 'Ежемесячно';
      case RecurrenceFrequency.yearly:
        return 'Ежегодно';
    }
  }

  Widget _buildControlPointCard(ControlPoint controlPoint) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          controlPoint.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controlPoint.description != null) ...[
              const SizedBox(height: 4),
              Text(controlPoint.description!),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${_getFrequencyText(controlPoint.frequency)} (каждые ${controlPoint.interval})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (controlPoint.assignee != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getUserDisplayName(controlPoint.assignee!),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  controlPoint.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: controlPoint.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  controlPoint.isActive ? 'Активна' : 'Неактивна',
                  style: TextStyle(
                    fontSize: 12,
                    color: controlPoint.isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
            if (controlPoint.metrics != null && controlPoint.metrics!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Метрик: ${controlPoint.metrics!.length}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        trailing: controlPoint.isActive
            ? Icon(Icons.radio_button_checked, color: Colors.green)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: () {
          // TODO: Переход на детальную страницу точки контроля
        },
      ),
    );
  }

  String _getUserDisplayName(ProfileUser user) {
    final parts = <String>[];
    if (user.lastName != null && user.lastName!.isNotEmpty) {
      parts.add(user.lastName!);
    }
    if (user.firstName != null && user.firstName!.isNotEmpty) {
      parts.add(user.firstName!);
    }
    if (user.patronymic != null && user.patronymic!.isNotEmpty) {
      parts.add(user.patronymic!);
    }
    return parts.isEmpty ? user.email : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final selectedBusiness = profileProvider.selectedBusiness;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Точки контроля'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadControlPoints(refresh: true),
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
            },
          ),
        ],
      ),
      body: selectedBusiness == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_center,
                      size: 48, color: Colors.orange.shade700),
                  const SizedBox(height: 12),
                  const Text(
                    'Необходимо выбрать компанию',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _isLoading && _controlPoints.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _controlPoints.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(fontSize: 16, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _loadControlPoints(refresh: true),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    )
                  : _controlPoints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.assessment,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text(
                                'Нет точек контроля',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadControlPoints(refresh: true),
                          child: ListView.builder(
                            itemCount: _controlPoints.length +
                                (_meta != null &&
                                        _meta!.page != null &&
                                        _meta!.totalPages != null &&
                                        _meta!.page! < _meta!.totalPages!
                                    ? 1
                                    : 0),
                            itemBuilder: (context, index) {
                              if (index == _controlPoints.length) {
                                // Кнопка загрузки следующей страницы
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _page++;
                                        });
                                        _loadControlPoints();
                                      },
                                      child: const Text('Загрузить еще'),
                                    ),
                                  ),
                                );
                              }
                              return _buildControlPointCard(_controlPoints[index]);
                            },
                          ),
                        ),
    );
  }
}
