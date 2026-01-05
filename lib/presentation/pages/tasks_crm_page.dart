import 'package:flutter/material.dart';

/// Страница задач по клиентам CRM
class TasksCrmPage extends StatelessWidget {
  const TasksCrmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Задачи по клиентам CRM'),
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
      body: const Center(child: Text('Задачи по клиентам CRM')),
    );
  }
}









