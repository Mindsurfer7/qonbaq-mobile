import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

/// Страница HR документов
class HrDocumentsPage extends StatelessWidget {
  const HrDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR документы'),
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
      body: const Center(child: Text('HR документы')),
    );
  }
}









