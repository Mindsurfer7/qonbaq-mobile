import 'package:flutter/material.dart';
import 'workday_dialog.dart';

/// Переиспользуемый виджет с кнопками для работы с рабочим днем
class WorkDayButtons extends StatelessWidget {
  const WorkDayButtons({super.key});

  void _showWorkDayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WorkDayDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showWorkDayDialog(context),
          icon: const Icon(Icons.access_time),
          label: const Text('Рабочий день'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}






