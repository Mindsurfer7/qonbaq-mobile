import 'package:flutter/material.dart';

/// Страница карточки сотрудника
class EmployeeCardPage extends StatelessWidget {
  const EmployeeCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карточка сотрудника'),
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
      body: const Center(child: Text('Карточка сотрудника')),
    );
  }
}









