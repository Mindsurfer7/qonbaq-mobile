import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';
import 'package:go_router/go_router.dart';

/// Страница человеческих ресурсов
class HumanResourcesPage extends StatelessWidget {
  const HumanResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Человеческие ресурсы'),
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
      body: const Center(child: Text('Человеческие ресурсы')),
    );
  }
}









