import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Виджет для отображения данных формы (formData) в режиме просмотра (read-only)
/// Использует formSchema для понимания структуры и типов полей
class FormDataViewer extends StatelessWidget {
  final Map<String, dynamic> formSchema;
  final Map<String, dynamic> formData;

  const FormDataViewer({
    super.key,
    required this.formSchema,
    required this.formData,
  });

  @override
  Widget build(BuildContext context) {
    final blocks = formSchema['blocks'] as List<dynamic>? ?? [];
    final blocksInfo = formSchema['blocks_info'] as Map<String, dynamic>? ?? {};

    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((blockName) {
        final blockNameStr = blockName.toString();
        final block = blocksInfo[blockNameStr] as Map<String, dynamic>?;
        
        if (block == null) return const SizedBox.shrink();
        
        return _buildBlock(context, blockNameStr, block);
      }).toList(),
    );
  }

  Widget _buildBlock(BuildContext context, String blockName, Map<String, dynamic> block) {
    final label = block['label'] as String? ?? blockName;
    final elements = block['elements'] as List<dynamic>? ?? [];

    if (elements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Собираем только видимые поля с данными
    final visibleFields = <Widget>[];
    for (final element in elements) {
      final field = _buildField(context, element as Map<String, dynamic>);
      if (field != null) {
        visibleFields.add(field);
      }
    }

    // Если нет видимых полей, не показываем блок
    if (visibleFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок блока
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        // Поля блока
        ...visibleFields,
      ],
    );
  }

  Widget? _buildField(BuildContext context, Map<String, dynamic> element) {
    final fieldName = element['name'] as String;
    final fieldLabel = element['label'] as String? ?? fieldName;
    final fieldType = element['type'] as String? ?? 'text';
    final props = element['props'] as Map<String, dynamic>? ?? {};
    
    // Проверяем видимость поля (условная видимость)
    final visible = props['visible'] as Map<String, dynamic>?;
    if (visible != null) {
      // Проверяем условие видимости
      bool isVisible = true;
      for (final entry in visible.entries) {
        final parentField = entry.key;
        final expectedValue = entry.value;
        final actualValue = formData[parentField];
        if (actualValue != expectedValue) {
          isVisible = false;
          break;
        }
      }
      if (!isVisible) {
        return null; // Поле не должно быть видимым
      }
    }
    
    // Получаем значение из formData
    final value = formData[fieldName];
    
    // Пропускаем поля без значений (но не пропускаем false для checkbox)
    if (value == null || (value is String && value.isEmpty)) {
      return null;
    }

    // Пропускаем поле processName (техническое поле)
    if (fieldName == 'processName') {
      return null;
    }

    // Пропускаем amount и currency - они отображаются в базовых полях
    if (fieldName == 'amount' || fieldName == 'currency') {
      return null;
    }

    // Пропускаем paymentDueDate - оно отображается в базовых полях
    if (fieldName == 'paymentDueDate') {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_getIconForFieldType(fieldType), size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fieldLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatValue(value, fieldType, element),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForFieldType(String type) {
    switch (type) {
      case 'number':
        return Icons.numbers;
      case 'date':
      case 'datetime':
        return Icons.calendar_today;
      case 'select':
        return Icons.list;
      case 'textarea':
        return Icons.notes;
      case 'checkbox':
        return Icons.check_box;
      case 'files':
        return Icons.attach_file;
      default:
        return Icons.text_fields;
    }
  }

  String _formatValue(dynamic value, String fieldType, Map<String, dynamic> element) {
    if (value == null) return 'Не указано';

    switch (fieldType) {
      case 'date':
      case 'datetime':
        try {
          final date = value is DateTime ? value : DateTime.parse(value.toString());
          return fieldType == 'date'
              ? DateFormat('dd.MM.yyyy').format(date)
              : DateFormat('dd.MM.yyyy HH:mm').format(date);
        } catch (e) {
          return value.toString();
        }

      case 'number':
        // Форматируем числа с разделителем тысяч
        try {
          final number = value is num ? value : num.parse(value.toString());
          return NumberFormat('#,##0.##', 'ru_RU').format(number);
        } catch (e) {
          return value.toString();
        }

      case 'checkbox':
        return value == true || value.toString().toLowerCase() == 'true' ? 'Да' : 'Нет';

      case 'select':
        // Попытаемся найти читаемое название в options
        final options = element['options'];
        if (options is List) {
          try {
            final option = options.firstWhere(
              (opt) => opt['value'].toString() == value.toString(),
              orElse: () => null,
            );
            if (option != null && option['name'] != null) {
              return option['name'].toString();
            }
          } catch (e) {
            // Ignore
          }
        }
        // Если не нашли в options, форматируем enum значение
        return _formatEnumValue(value.toString());

      default:
        return value.toString();
    }
  }

  /// Форматирует enum значения (например, BANK_TRANSFER -> Банковский перевод)
  String _formatEnumValue(String value) {
    // Словарь для перевода известных значений
    const translations = {
      // Payment methods
      'CASH': 'Наличные',
      'BANK_TRANSFER': 'Банковский перевод',
      'CARD': 'Банковская карта',
      
      // Expense articles
      'PRODUCTION': 'Производство',
      'ADMINISTRATIVE': 'Административные расходы',
      'MARKETING': 'Маркетинг',
      'SALES': 'Продажи',
      'OTHER': 'Прочее',
      
      // Periodicity
      'CONSTANT': 'Постоянные',
      'VARIABLE': 'Переменные',
      
      // Categories
      'LABOR_FUND': 'Фонд оплаты труда',
      'TAXES': 'Налоги',
      'TRAVEL': 'Командировочные',
      'COMMON': 'Общие расходы',
      
      // Category details
      'LABOR_FUND_TOTAL': 'Фонд оплаты труда',
      'SALARY': 'Оклад, заработная плата',
      'BONUS': 'Бонусная часть оплаты труда',
      'OUTSOURCING': 'Оплата труда аутсорсинг',
      'TAXES_GENERAL': 'Налоги',
      'COMPANY_TAXES': 'Налоги по компании',
      'PAYROLL_TAXES': 'Налоги по зп',
      'TAXES_FINES': 'Налоги, штрафы и пеня',
      'COUNTERPARTY_FINES': 'Штрафы и пеня по контрагентам',
      'TRAVEL_GENERAL': 'Командировочные',
      'DAILY_ALLOWANCE': 'Суточные (командировка)',
      'ACCOMMODATION': 'Проживание (командировка)',
      'RENT_PREMISES': 'Аренда помещений',
      'INTERNET_PHONE': 'Интернет, телефония и т.п.',
      'RENT_TRANSPORT': 'Аренда транспорта',
      'SOFTWARE_MAINTENANCE': 'Обслуживание ПО и приложений IT',
      'FUEL_MATERIALS': 'ГСМ и расходные материалы (транспорт)',
      'STATIONERY': 'Канцелярские товары',
      'PREMISES_REPAIR': 'Текущий ремонт и обслуживание помещений',
      'FIXED_ASSETS': 'Основные средства',
      'CONSUMABLES': 'Расходные материалы',
      'DAMAGE_COMPENSATION': 'Возмещение ущерба',
      'REPRESENTATION': 'Представительские расходы',
    };

    final translated = translations[value];
    if (translated != null) return translated;
    
    // Если перевод не найден, форматируем: SOME_VALUE -> Some Value
    return value.split('_').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
