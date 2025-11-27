import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

/// Страница профиля и настроек
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProfileProvider>(context, listen: false);
      provider.loadBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль / настройки'),
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
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadBusinesses(),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          if (provider.businesses == null || provider.businesses!.isEmpty) {
            return const Center(child: Text('Нет доступных компаний'));
          }

          return _buildContent(provider);
        },
      ),
    );
  }

  Widget _buildContent(ProfileProvider provider) {
    return Column(
      children: [
        // Если компаний несколько, показываем селектор
        if (provider.businesses!.length > 1)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField(
              value: provider.selectedBusiness,
              decoration: const InputDecoration(
                labelText: 'Выберите компанию',
                border: OutlineInputBorder(),
              ),
              items:
                  provider.businesses!
                      .map(
                        (business) => DropdownMenuItem(
                          value: business,
                          child: Text(business.name),
                        ),
                      )
                      .toList(),
              onChanged: (business) {
                if (business != null) {
                  provider.selectBusiness(business);
                }
              },
            ),
          ),
        Expanded(
          child:
              provider.profile != null
                  ? _buildProfile(provider)
                  : const Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }

  Widget _buildProfile(ProfileProvider provider) {
    final profile = provider.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Центральная кнопка "На главную"
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/business');
                },
                icon: const Icon(Icons.home),
                label: const Text('На главную'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          // Сетка с секциями
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              // Данные о работнике
              _buildEmployeeDataCard(profile),
              // Позиция в организационной структуре
              _buildOrgStructureCard(profile),
              // Пригласить новых коллег
              _buildInviteColleaguesCard(),
              // Кадровые документы
              _buildHrDocumentsCard(profile),
            ],
          ),
          // Взаимозаменяемый работник (отдельно)
          if (profile.interchangeableEmployee != null)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Взаимозаменяемый работник',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. ФИО работника: ${profile.interchangeableEmployee!.fullName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDataCard(UserProfile profile) {
    final data = profile.employeeData;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Данные о работнике',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (data.photo != null)
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(data.photo!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 80,
                width: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: const Icon(Icons.person, size: 40),
              ),
            const SizedBox(height: 8),
            const Text(
              'Фото сотрудника',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildFieldRow('1. Фамилия', data.lastName ?? '-'),
            _buildFieldRow('2. Имя', data.firstName ?? '-'),
            _buildFieldRow('3. Отчество', data.patronymic ?? '-'),
            _buildFieldRow('4. Отдел', data.department ?? '-'),
            _buildFieldRow(
              '5. Должность',
              data.position ?? '-',
              isHighlighted: true,
            ),
            _buildFieldRow(
              '6. Дата принятия на работу',
              data.hireDate?.toString().split(' ').first ?? '-',
            ),
            _buildFieldRow('7. Тип должности', data.positionType ?? '-'),
            _buildFieldRow('8. Электронная почта', data.email ?? '-'),
            _buildFieldRow('9. Номер телефона(рабочий)', data.workPhone ?? '-'),
            _buildFieldRow('10. Стаж работы', data.workExperience ?? '-'),
            _buildFieldRow(
              '11. Подотчёт (ОС, РМ, ДС)',
              data.accountability ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgStructureCard(UserProfile profile) {
    final org = profile.orgStructure;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Позиция в организационной структуре',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildOrgPositionRow(
              '1. Генеральный директор',
              org.isGeneralDirector,
              org.currentPosition == 'Генеральный директор',
            ),
            _buildOrgPositionRow(
              '2. Руководитель проекта(управления)',
              org.isProjectManager,
              org.currentPosition == 'Руководитель проекта(управления)',
            ),
            _buildOrgPositionRow(
              '3. Руководитель отдела',
              org.isDepartmentHead,
              org.currentPosition == 'Руководитель отдела',
            ),
            _buildOrgPositionRow(
              '4. Должность работника',
              org.isEmployee,
              org.currentPosition == 'Должность работника',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgPositionRow(String label, bool isActive, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isCurrent ? Colors.green : Colors.black,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isActive) const Icon(Icons.check, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildInviteColleaguesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Пригласить новых коллег',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Приглашение по телефону')),
                );
              },
              icon: const Icon(Icons.phone),
              label: const Text('1. по номеру телефона'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Приглашение по email')),
                );
              },
              icon: const Icon(Icons.email),
              label: const Text('2. по электронной почте'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHrDocumentsCard(UserProfile profile) {
    final documents = profile.hrDocuments;
    final personnelNumber = profile.employment.personnelNumber ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Кадровые документы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Табельный номер',
                hintText: personnelNumber.isEmpty ? '_____' : personnelNumber,
                border: const OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            ...documents.asMap().entries.map((entry) {
              final index = entry.key + 1;
              final doc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text('$index. ${doc.title}')),
                    if (doc.fileUrl != null)
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          // TODO: Открыть/скачать документ
                        },
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Colors.green : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
