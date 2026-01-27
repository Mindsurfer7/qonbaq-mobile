import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/repositories/chat_repository.dart';
import 'employees_list_page.dart';
import 'anonymous_chats_list_page.dart';

/// Страница чатов, почты и телефонии
class ChatsEmailPage extends StatefulWidget {
  const ChatsEmailPage({super.key});

  @override
  State<ChatsEmailPage> createState() => _ChatsEmailPageState();
}

class _ChatsEmailPageState extends State<ChatsEmailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRepository = Provider.of<ChatRepository>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты, почта, телефония'),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Сотрудники',
            ),
            Tab(
              icon: Icon(Icons.person_outline),
              text: 'Клиенты',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Таб с чатами сотрудников
          const EmployeesListPage(),
          // Таб с анонимными чатами
          AnonymousChatsListPage(
            chatRepository: chatRepository,
          ),
        ],
      ),
    );
  }
}




