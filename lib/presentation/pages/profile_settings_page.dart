import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/theme/theme_extensions.dart';
import '../providers/profile_provider.dart';
import '../providers/invite_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/business_selector_widget.dart';

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

      // Загружаем текущий активный инвайт
      final inviteProvider = Provider.of<InviteProvider>(
        context,
        listen: false,
      );
      inviteProvider.loadCurrentInvite();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль / настройки'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              context.go('/business');
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
        // Переиспользуемый виджет выбора компании
        const BusinessSelectorWidget(compact: false),
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
                  context.go('/business');
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
          // Сетка с секциями (кастомная сетка для поддержки динамической высоты)
          Column(
            children: [
              // Первый ряд карточек
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildEmployeeDataCard(profile)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildOrgStructureCard(profile)),
                ],
              ),
              const SizedBox(height: 16),
              // Второй ряд карточек
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildInviteColleaguesCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildHrDocumentsCard(profile)),
                ],
              ),
              const SizedBox(height: 16),
              // Третий ряд - карточка с настройками темы (на всю ширину)
              _buildThemeSettingsCard(),
            ],
          ),
          // Взаимозаменяемый работник (отдельно)
          if (profile.interchangeableEmployee != null)
            Card(
              margin: const EdgeInsets.only(top: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
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
    return Consumer<InviteProvider>(
      builder: (context, inviteProvider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Пригласить новых коллег',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Если есть активный инвайт, показываем ссылки сразу
                if (inviteProvider.inviteResult != null) ...[
                  // Web ссылка
                  const Text(
                    'Web ссылка (для браузера):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: inviteProvider.inviteResult!.links.web,
                          ),
                          readOnly: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: inviteProvider.inviteResult!.links.web,
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Web ссылка скопирована'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        tooltip: 'Копировать web ссылку',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // QR-код для веб-ссылки
                  const Text(
                    'QR-код для регистрации:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Отсканируйте QR-код, чтобы открыть ссылку на регистрацию в браузере.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: inviteProvider.inviteResult!.links.web,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  // Закомментировано: Deep link для мобильных приложений
                  // const SizedBox(height: 16),
                  // const Text(
                  //   'Deep link (для мобильных приложений):',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   'Используйте для SMS, мессенджеров, QR-кодов. При клике откроется приложение.',
                  //   style: TextStyle(
                  //     fontSize: 11,
                  //     color: Colors.grey.shade600,
                  //     fontStyle: FontStyle.italic,
                  //   ),
                  // ),
                  // const SizedBox(height: 8),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextField(
                  //         controller: TextEditingController(
                  //           text: inviteProvider.inviteResult!.links.deepLink,
                  //         ),
                  //         readOnly: true,
                  //         decoration: const InputDecoration(
                  //           border: OutlineInputBorder(),
                  //           contentPadding: EdgeInsets.symmetric(
                  //             horizontal: 12,
                  //             vertical: 8,
                  //           ),
                  //         ),
                  //         style: const TextStyle(fontSize: 12),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     IconButton(
                  //       icon: const Icon(Icons.copy),
                  //       onPressed: () async {
                  //         await Clipboard.setData(
                  //           ClipboardData(
                  //             text: inviteProvider.inviteResult!.links.deepLink,
                  //           ),
                  //         );
                  //         if (context.mounted) {
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             const SnackBar(
                  //               content: Text('Deep link скопирован'),
                  //               duration: Duration(seconds: 2),
                  //             ),
                  //           );
                  //         }
                  //       },
                  //       tooltip: 'Копировать deep link',
                  //     ),
                  //   ],
                  // ),
                ]
                // Если активного инвайта нет, показываем кнопку "Пригласить"
                else ...[
                  // Кнопка "Пригласить"
                  ElevatedButton.icon(
                    onPressed:
                        inviteProvider.isLoading
                            ? null
                            : () async {
                              await inviteProvider.createInviteLink();
                            },
                    icon:
                        inviteProvider.isLoading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.person_add),
                    label: Text(
                      inviteProvider.isLoading ? 'Создание...' : 'Пригласить',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  // Показываем ошибку, если есть
                  if (inviteProvider.error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      inviteProvider.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  // Показываем ссылки после успешного создания (если только что создали)
                  if (inviteProvider.inviteResult != null) ...[
                    const SizedBox(height: 16),
                    // Web ссылка
                    const Text(
                      'Web ссылка (для браузера):',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: TextEditingController(
                              text: inviteProvider.inviteResult!.links.web,
                            ),
                            readOnly: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: inviteProvider.inviteResult!.links.web,
                              ),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Web ссылка скопирована'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          tooltip: 'Копировать web ссылку',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // QR-код для веб-ссылки
                    const Text(
                      'QR-код для регистрации:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Отсканируйте QR-код, чтобы открыть ссылку на регистрацию в браузере.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: inviteProvider.inviteResult!.links.web,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    // Закомментировано: Deep link для мобильных приложений
                    // const SizedBox(height: 16),
                    // const Text(
                    //   'Deep link (для мобильных приложений):',
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     fontWeight: FontWeight.w500,
                    //   ),
                    // ),
                    // const SizedBox(height: 4),
                    // Text(
                    //   'Используйте для SMS, мессенджеров, QR-кодов. При клике откроется приложение.',
                    //   style: TextStyle(
                    //     fontSize: 11,
                    //     color: Colors.grey.shade600,
                    //     fontStyle: FontStyle.italic,
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: TextField(
                    //         controller: TextEditingController(
                    //           text: inviteProvider.inviteResult!.links.deepLink,
                    //         ),
                    //         readOnly: true,
                    //         decoration: const InputDecoration(
                    //           border: OutlineInputBorder(),
                    //           contentPadding: EdgeInsets.symmetric(
                    //             horizontal: 12,
                    //             vertical: 8,
                    //           ),
                    //         ),
                    //         style: const TextStyle(fontSize: 12),
                    //       ),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     IconButton(
                    //       icon: const Icon(Icons.copy),
                    //       onPressed: () async {
                    //         await Clipboard.setData(
                    //           ClipboardData(
                    //             text: inviteProvider.inviteResult!.links.deepLink,
                    //           ),
                    //         );
                    //         if (context.mounted) {
                    //           ScaffoldMessenger.of(context).showSnackBar(
                    //             const SnackBar(
                    //               content: Text('Deep link скопирован'),
                    //               duration: Duration(seconds: 2),
                    //             ),
                    //           );
                    //         }
                    //       },
                    //       tooltip: 'Копировать deep link',
                    //     ),
                    //   ],
                    // ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHrDocumentsCard(UserProfile profile) {
    final documents = profile.hrDocuments;
    final personnelNumber = profile.employment.personnelNumber ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

  Widget _buildThemeSettingsCard() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = context.appTheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Настройки темы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: theme.accentPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          themeProvider.isDarkMode
                              ? 'Темная тема'
                              : 'Светлая тема',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: theme.accentPrimary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
