import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/usecases/get_customer.dart';
import '../../domain/usecases/get_customer_contacts.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/assign_customer_responsible.dart';
import '../../core/error/failures.dart';
import '../../data/models/validation_error.dart';
import '../providers/profile_provider.dart';
import '../widgets/create_task_form.dart';
import '../widgets/user_selector_widget.dart';
import '../../domain/repositories/user_repository.dart';

/// Страница детальной информации о клиенте
class CustomerDetailPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailPage({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  Customer? _customer;
  List<CustomerContact>? _contacts;
  bool _isLoading = true;
  bool _isLoadingContacts = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Бизнес не выбран';
      });
      return;
    }

    final getCustomerUseCase = Provider.of<GetCustomer>(context, listen: false);
    final result = await getCustomerUseCase.call(
      GetCustomerParams(
        id: widget.customerId,
        businessId: businessId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_error ?? 'Ошибка при загрузке клиента'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (customer) {
        setState(() {
          _isLoading = false;
          _customer = customer;
        });
        _loadContacts();
      },
    );
  }

  Future<void> _loadContacts() async {
    if (_customer == null) return;

    setState(() {
      _isLoadingContacts = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;

    if (businessId == null) {
      setState(() {
        _isLoadingContacts = false;
      });
      return;
    }

    final getContactsUseCase = Provider.of<GetCustomerContacts>(
      context,
      listen: false,
    );
    final result = await getContactsUseCase.call(
      GetCustomerContactsParams(
        customerId: widget.customerId,
        businessId: businessId,
      ),
    );

    result.fold(
      (failure) {
        setState(() {
          _isLoadingContacts = false;
        });
        // Не показываем ошибку, просто оставляем список пустым
      },
      (contacts) {
        setState(() {
          _isLoadingContacts = false;
          _contacts = contacts;
        });
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year}';
  }

  String _getCustomerTypeText(CustomerType type) {
    switch (type) {
      case CustomerType.individual:
        return 'Физическое лицо';
      case CustomerType.legalEntity:
        return 'Юридическое лицо';
    }
  }

  String _getSalesFunnelStageText(SalesFunnelStage? stage) {
    if (stage == null) return '—';
    switch (stage) {
      case SalesFunnelStage.unprocessed:
        return 'Необработанные';
      case SalesFunnelStage.inProgress:
        return 'В работе';
      case SalesFunnelStage.interested:
        return 'Заинтересованы';
      case SalesFunnelStage.contractSigned:
        return 'Заключен договор';
      case SalesFunnelStage.salesByContract:
        return 'Продажи по договору';
      case SalesFunnelStage.refused:
        return 'Отказ по причине';
    }
  }

  String _getContactTypeText(CustomerContactType type) {
    switch (type) {
      case CustomerContactType.phoneWork:
        return 'Рабочий телефон';
      case CustomerContactType.phoneMobile:
        return 'Мобильный телефон';
      case CustomerContactType.phoneFax:
        return 'Факс';
      case CustomerContactType.phoneHome:
        return 'Домашний телефон';
      case CustomerContactType.phonePager:
        return 'Пейджер';
      case CustomerContactType.phoneNewsletter:
        return 'Телефон для рассылок';
      case CustomerContactType.phoneOther:
        return 'Другой телефон';
      case CustomerContactType.emailWork:
        return 'Рабочая почта';
      case CustomerContactType.emailPersonal:
        return 'Личная почта';
      case CustomerContactType.emailNewsletter:
        return 'Почта для рассылок';
      case CustomerContactType.emailOther:
        return 'Другая почта';
      case CustomerContactType.websiteCorp:
        return 'Корпоративный сайт';
      case CustomerContactType.websitePersonal:
        return 'Личный сайт';
      case CustomerContactType.socialFacebook:
        return 'Facebook';
      case CustomerContactType.socialVk:
        return 'ВКонтакте';
      case CustomerContactType.socialInstagram:
        return 'Instagram';
      case CustomerContactType.socialTelegram:
        return 'Telegram';
      case CustomerContactType.socialTelegramId:
        return 'Telegram ID';
      case CustomerContactType.socialViber:
        return 'Viber';
      case CustomerContactType.socialTwitter:
        return 'Twitter';
      case CustomerContactType.socialLivejournal:
        return 'LiveJournal';
      case CustomerContactType.socialAvito:
        return 'Авито';
      case CustomerContactType.other:
        return 'Другое';
    }
  }

  IconData _getContactTypeIcon(CustomerContactType type) {
    if (type.toString().contains('phone')) {
      return Icons.phone;
    } else if (type.toString().contains('email')) {
      return Icons.email;
    } else if (type.toString().contains('website')) {
      return Icons.language;
    } else if (type.toString().contains('social')) {
      return Icons.public;
    }
    return Icons.contact_mail;
  }

  Widget _buildInfoRow(String label, String? value, IconData icon) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    if (_customer == null) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бизнес не выбран'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final createTaskUseCase = Provider.of<CreateTask>(context, listen: false);
    final userRepository = Provider.of<UserRepository>(context, listen: false);
    final customerName = _customer!.displayName ?? 
                        _customer!.name ?? 
                        'Клиент';

    showDialog(
      context: context,
      builder: (context) => _CreateTaskDialog(
        businessId: businessId,
        userRepository: userRepository,
        createTaskUseCase: createTaskUseCase,
        customerId: _customer!.id,
        customerName: customerName,
      ),
    );
  }

  void _showAssignResponsibleDialog() {
    if (_customer == null) return;

    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final businessId = profileProvider.selectedBusiness?.id;
    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бизнес не выбран'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final assignResponsibleUseCase = Provider.of<AssignCustomerResponsible>(
      context,
      listen: false,
    );
    final userRepository = Provider.of<UserRepository>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => _AssignResponsibleDialog(
        businessId: businessId,
        customerId: _customer!.id,
        currentResponsibleId: _customer!.responsibleId,
        userRepository: userRepository,
        assignResponsibleUseCase: assignResponsibleUseCase,
        onAssigned: () {
          _loadCustomer(); // Перезагружаем данные клиента
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.displayName ?? 'Клиент'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_customer != null)
            IconButton(
              icon: const Icon(Icons.add_task),
              onPressed: () => _showCreateTaskDialog(),
              tooltip: 'Создать задачу',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCustomer,
            tooltip: 'Обновить',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/business');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCustomer,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _customer == null
                  ? const Center(child: Text('Клиент не найден'))
                  : RefreshIndicator(
                      onRefresh: _loadCustomer,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Заголовок
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _customer!.customerType ==
                                            CustomerType.individual
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _customer!.customerType ==
                                            CustomerType.individual
                                        ? Icons.person
                                        : Icons.business,
                                    color: _customer!.customerType ==
                                            CustomerType.individual
                                        ? Colors.blue
                                        : Colors.green,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _customer!.displayName ??
                                            _customer!.name ??
                                            'Без названия',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_customer!.salesFunnelStage != null)
                                        ...[
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getSalesFunnelStageText(
                                                  _customer!.salesFunnelStage),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Основная информация
                            const Text(
                              'Основная информация',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Тип клиента',
                              _getCustomerTypeText(_customer!.customerType),
                              Icons.category,
                            ),
                            _buildInfoRow('ID', _customer!.id, Icons.tag),
                            _buildInfoRow(
                              'Название',
                              _customer!.name,
                              Icons.business_center,
                            ),
                            if (_customer!.customerType == CustomerType.legalEntity) ...[
                              _buildInfoRow('БИН', _customer!.bin, Icons.numbers),
                              _buildInfoRow('ОКПО', _customer!.okpo, Icons.numbers),
                              _buildInfoRow(
                                'Полное название (каз)',
                                _customer!.fullNameKaz,
                                Icons.translate,
                              ),
                              _buildInfoRow(
                                'Краткое название (каз)',
                                _customer!.shortNameKaz,
                                Icons.translate,
                              ),
                            ],
                            if (_customer!.customerType == CustomerType.individual) ...[
                              _buildInfoRow('ИИН', _customer!.iin, Icons.badge),
                              _buildInfoRow(
                                'Фамилия',
                                _customer!.lastName,
                                Icons.person,
                              ),
                              _buildInfoRow(
                                'Имя',
                                _customer!.firstName,
                                Icons.person,
                              ),
                              _buildInfoRow(
                                'Отчество',
                                _customer!.patronymic,
                                Icons.person,
                              ),
                            ],
                            _buildInfoRow('Тип', _customer!.type, Icons.info),
                            _buildInfoRow(
                              'Размер компании',
                              _customer!.companySize,
                              Icons.group,
                            ),
                            _buildInfoRow(
                              'Отрасль',
                              _customer!.industry,
                              Icons.work,
                            ),
                            if (_customer!.annualTurnover != null)
                              _buildInfoRow(
                                'Годовой оборот',
                                '${_customer!.annualTurnover!.toStringAsFixed(2)} ${_customer!.currency ?? '₸'}',
                                Icons.attach_money,
                              ),
                            _buildInfoRow(
                              'Валюта',
                              _customer!.currency,
                              Icons.monetization_on,
                            ),

                            // Воронка продаж
                            if (_customer!.salesFunnelStage != null ||
                                _customer!.refusalReason != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Воронка продаж',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Стадия',
                                _getSalesFunnelStageText(
                                    _customer!.salesFunnelStage),
                                Icons.trending_up,
                              ),
                              _buildInfoRow(
                                'Причина отказа',
                                _customer!.refusalReason,
                                Icons.cancel,
                              ),
                            ],

                            // Ответственные
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ответственные',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showAssignResponsibleDialog(),
                                  tooltip: 'Изменить ответственного',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_customer!.responsible != null)
                              _buildInfoRow(
                                'Ответственный',
                                '${_customer!.responsible!.name} (${_customer!.responsible!.email})',
                                Icons.person,
                              )
                            else if (_customer!.responsibleId != null)
                              _buildInfoRow(
                                'Ответственный ID',
                                _customer!.responsibleId,
                                Icons.person,
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 20, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ответственный не назначен',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Казахстан-специфичные поля
                            if (_customer!.kbe != null ||
                                _customer!.headFullName != null ||
                                _customer!.headPosition != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Дополнительная информация',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow('КБЕ', _customer!.kbe, Icons.info),
                              _buildInfoRow(
                                'ФИО руководителя',
                                _customer!.headFullName,
                                Icons.person_outline,
                              ),
                              _buildInfoRow(
                                'Должность руководителя',
                                _customer!.headPosition,
                                Icons.work_outline,
                              ),
                            ],

                            // UTM метки
                            if (_customer!.utmSource != null ||
                                _customer!.utmMedium != null ||
                                _customer!.utmCampaign != null ||
                                _customer!.utmContent != null ||
                                _customer!.utmTerm != null) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'UTM метки',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'UTM Source',
                                _customer!.utmSource,
                                Icons.link,
                              ),
                              _buildInfoRow(
                                'UTM Medium',
                                _customer!.utmMedium,
                                Icons.link,
                              ),
                              _buildInfoRow(
                                'UTM Campaign',
                                _customer!.utmCampaign,
                                Icons.link,
                              ),
                              _buildInfoRow(
                                'UTM Content',
                                _customer!.utmContent,
                                Icons.link,
                              ),
                              _buildInfoRow(
                                'UTM Term',
                                _customer!.utmTerm,
                                Icons.link,
                              ),
                            ],

                            // Дополнительно
                            if (_customer!.comment != null ||
                                _customer!.contractNumber != null ||
                                _customer!.isKeyClient ||
                                _customer!.deletedIn1C ||
                                _customer!.createdFromCRMForm) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Дополнительно',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow(
                                'Комментарий',
                                _customer!.comment,
                                Icons.comment,
                              ),
                              _buildInfoRow(
                                'Номер договора',
                                _customer!.contractNumber,
                                Icons.description,
                              ),
                              if (_customer!.isKeyClient)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star,
                                          size: 20, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Ключевой клиент',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_customer!.deletedIn1C)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete,
                                          size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Удален в 1С',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_customer!.createdFromCRMForm)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Icon(Icons.web,
                                          size: 20, color: Colors.blue),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Создан из CRM формы',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                            ],

                            // Даты
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'Даты',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              'Создан',
                              _formatDateTime(_customer!.createdAt),
                              Icons.calendar_today,
                            ),
                            _buildInfoRow(
                              'Обновлен',
                              _formatDateTime(_customer!.updatedAt),
                              Icons.update,
                            ),
                            _buildInfoRow(
                              'Последняя активность',
                              _formatDate(_customer!.lastActivity),
                              Icons.access_time,
                            ),
                            _buildInfoRow(
                              'Последняя коммуникация',
                              _formatDate(_customer!.lastCommunication),
                              Icons.chat_bubble_outline,
                            ),
                            _buildInfoRow(
                              'Контакт создан',
                              _formatDate(_customer!.contactCreatedAt),
                              Icons.contact_mail,
                            ),

                            // Контакты
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Контакты',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_isLoadingContacts)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_contacts == null || _contacts!.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'Нет контактов',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...(_contacts!.map((contact) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: Icon(
                                      _getContactTypeIcon(contact.type),
                                      color: theme.colorScheme.primary,
                                    ),
                                    title: Text(
                                      contact.label ??
                                          _getContactTypeText(contact.type),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(contact.value),
                                    trailing: contact.isPrimary
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Основной',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                );
                              }).toList()),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

/// Диалог создания задачи для клиента
class _CreateTaskDialog extends StatefulWidget {
  final String businessId;
  final UserRepository userRepository;
  final CreateTask createTaskUseCase;
  final String customerId;
  final String customerName;

  const _CreateTaskDialog({
    required this.businessId,
    required this.userRepository,
    required this.createTaskUseCase,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  String? _error;
  List<ValidationError>? _validationErrors;

  String _getErrorMessage(Failure failure) {
    if (failure is ValidationFailure) {
      return failure.serverMessage ?? failure.message;
    } else if (failure is ServerFailure) {
      return failure.message;
    } else if (failure is NetworkFailure) {
      return failure.message;
    }
    return 'Произошла ошибка';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            AppBar(
              title: const Text('Создать задачу'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: CreateTaskForm(
                businessId: widget.businessId,
                userRepository: widget.userRepository,
                customerId: widget.customerId,
                customerName: widget.customerName,
                error: _error,
                validationErrors: _validationErrors,
                onError: (error) {
                  setState(() {
                    _error = error;
                  });
                },
                onSubmit: (task) async {
                  final result = await widget.createTaskUseCase.call(
                    CreateTaskParams(task: task),
                  );

                  result.fold(
                    (failure) {
                      // Обрабатываем ошибки валидации
                      if (failure is ValidationFailure) {
                        setState(() {
                          _error = failure.serverMessage ?? failure.message;
                          _validationErrors = failure.errors;
                        });
                      } else {
                        setState(() {
                          _error = _getErrorMessage(failure);
                          _validationErrors = null;
                        });
                      }
                    },
                    (createdTask) {
                      // Закрываем диалог и показываем успех
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Задача успешно создана'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  );
                },
                onCancel: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Диалог назначения ответственного за клиента
class _AssignResponsibleDialog extends StatefulWidget {
  final String businessId;
  final String customerId;
  final String? currentResponsibleId;
  final UserRepository userRepository;
  final AssignCustomerResponsible assignResponsibleUseCase;
  final VoidCallback onAssigned;

  const _AssignResponsibleDialog({
    required this.businessId,
    required this.customerId,
    this.currentResponsibleId,
    required this.userRepository,
    required this.assignResponsibleUseCase,
    required this.onAssigned,
  });

  @override
  State<_AssignResponsibleDialog> createState() => _AssignResponsibleDialogState();
}

class _AssignResponsibleDialogState extends State<_AssignResponsibleDialog> {
  String? _selectedUserId;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedUserId = widget.currentResponsibleId;
  }

  Future<void> _assignResponsible() async {
    if (_selectedUserId == null) {
      setState(() {
        _error = 'Выберите ответственного';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.assignResponsibleUseCase.call(
      AssignCustomerResponsibleParams(
        customerId: widget.customerId,
        businessId: widget.businessId,
        responsibleId: _selectedUserId!,
      ),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoading = false;
          _error = _getErrorMessage(failure);
        });
      },
      (customer) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
        widget.onAssigned();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ответственный успешно назначен'),
            backgroundColor: Colors.green,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Назначить ответственного'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserSelectorWidget(
                    businessId: widget.businessId,
                    userRepository: widget.userRepository,
                    selectedUserId: _selectedUserId,
                    onUserSelected: (userId) {
                      setState(() {
                        _selectedUserId = userId;
                        _error = null;
                      });
                    },
                    label: 'Ответственный',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Отмена'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _assignResponsible,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Назначить'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
