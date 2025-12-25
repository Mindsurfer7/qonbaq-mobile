import 'package:flutter/material.dart';

/// Страница начала рабочего дня
class StartWorkDayPage extends StatelessWidget {
  const StartWorkDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Начать рабочий день'),
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
      body: const Center(child: Text('Начать рабочий день / Завершить')),
    );
  }
}







