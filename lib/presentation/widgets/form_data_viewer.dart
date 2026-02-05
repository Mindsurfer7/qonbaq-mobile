import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import '../../domain/usecases/download_file.dart';

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
      children:
          blocks.map((blockName) {
            final blockNameStr = blockName.toString();
            final block = blocksInfo[blockNameStr] as Map<String, dynamic>?;

            if (block == null) return const SizedBox.shrink();

            return _buildBlock(context, blockNameStr, block);
          }).toList(),
    );
  }

  Widget _buildBlock(
    BuildContext context,
    String blockName,
    Map<String, dynamic> block,
  ) {
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

    // Для типа files используем специальный виджет
    if (fieldType == 'files') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: FormDataFileWidget(
          fieldLabel: fieldLabel,
          fileData: value,
        ),
      );
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

  String _formatValue(
    dynamic value,
    String fieldType,
    Map<String, dynamic> element,
  ) {
    if (value == null) return 'Не указано';

    switch (fieldType) {
      case 'date':
      case 'datetime':
        try {
          final date =
              value is DateTime ? value : DateTime.parse(value.toString());
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
        return value == true || value.toString().toLowerCase() == 'true'
            ? 'Да'
            : 'Нет';

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
    return value
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}

/// Виджет для отображения файла из formData
/// Поддерживает новый формат с объектом, содержащим fileId, url, expiresAt, key, extension, module
class FormDataFileWidget extends StatefulWidget {
  final String fieldLabel;
  final dynamic fileData; // Может быть String (старый формат) или Map (новый формат)

  const FormDataFileWidget({
    super.key,
    required this.fieldLabel,
    required this.fileData,
  });

  @override
  State<FormDataFileWidget> createState() => _FormDataFileWidgetState();
}

class _FormDataFileWidgetState extends State<FormDataFileWidget> {
  String? _currentUrl;
  bool _isLoading = false;
  String? _error;
  DateTime? _expiresAt;
  String? _fileExtension;
  String? _module;

  @override
  void initState() {
    super.initState();
    _initializeFileData();
  }

  void _initializeFileData() {
    if (widget.fileData == null) return;

    // Новый формат: объект с полями
    if (widget.fileData is Map<String, dynamic>) {
      final fileObj = widget.fileData as Map<String, dynamic>;
      _currentUrl = fileObj['url'] as String?;
      _fileExtension = fileObj['extension'] as String?;
      _module = fileObj['module'] as String? ?? 'attachments';
      
      // Парсим expiresAt
      final expiresAtStr = fileObj['expiresAt'] as String?;
      if (expiresAtStr != null) {
        try {
          _expiresAt = DateTime.parse(expiresAtStr);
        } catch (e) {
          // Игнорируем ошибки парсинга
        }
      }

      // Проверяем, не истек ли URL
      if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
        // URL истек, нужно получить новый через key
        _loadNewUrl(fileObj['key'] as String?);
      }
    } else if (widget.fileData is String) {
      // Старый формат: просто fileId (для обратной совместимости)
      // В этом случае не можем показать файл без дополнительного запроса
      _error = 'Формат файла не поддерживается';
    }
  }

  Future<void> _loadNewUrl(String? key) async {
    if (key == null || _module == null) {
      setState(() {
        _error = 'Недостаточно данных для загрузки файла';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final downloadFileUseCase = Provider.of<DownloadFile>(
        context,
        listen: false,
      );

      final result = await downloadFileUseCase.call(
        DownloadFileParams(
          key: key,
          module: _module!,
          expiresIn: 3600,
        ),
      );

      result.fold(
        (failure) {
          setState(() {
            _error = failure.message;
            _isLoading = false;
          });
        },
        (urlResponse) {
          setState(() {
            _currentUrl = urlResponse.url;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки файла: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openFile() async {
    String? urlToUse = _currentUrl;

    // Если URL истек, пытаемся получить новый
    if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
      if (widget.fileData is Map<String, dynamic>) {
        final fileObj = widget.fileData as Map<String, dynamic>;
        await _loadNewUrl(fileObj['key'] as String?);
        urlToUse = _currentUrl;
      }
    }

    if (urlToUse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить ссылку на файл'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final uri = Uri.parse(urlToUse);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось открыть файл'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile() async {
    String? urlToUse = _currentUrl;

    // Если URL истек, пытаемся получить новый
    if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now())) {
      if (widget.fileData is Map<String, dynamic>) {
        final fileObj = widget.fileData as Map<String, dynamic>;
        await _loadNewUrl(fileObj['key'] as String?);
        urlToUse = _currentUrl;
      }
    }

    if (urlToUse == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось получить ссылку на файл'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Скачиваем файл по полученной URL
      final response = await http.get(Uri.parse(urlToUse));

      if (response.statusCode != 200) {
        throw Exception('Ошибка скачивания файла: ${response.statusCode}');
      }

      if (kIsWeb) {
        // Для веба открываем файл в новой вкладке
        final uri = Uri.parse(urlToUse);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('Не удалось открыть файл');
        }
      } else {
        // Для мобильных платформ сохраняем файл и используем share
        final fileName = _getFileName();
        final directory = await getApplicationDocumentsDirectory();
        final filePath = path.join(directory.path, fileName);
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);

        // Используем share для открытия файла
        final xFile = XFile(filePath);
        await Share.shareXFiles(
          [xFile],
          text: fileName,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл успешно скачан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка скачивания файла: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFileName() {
    if (widget.fileData is Map<String, dynamic>) {
      final fileObj = widget.fileData as Map<String, dynamic>;
      final key = fileObj['key'] as String?;
      if (key != null) {
        // Извлекаем имя файла из key (например, "attachments/uuid.pdf" -> "uuid.pdf")
        final parts = key.split('/');
        if (parts.isNotEmpty) {
          return parts.last;
        }
      }
      final fileId = fileObj['fileId'] as String?;
      final extension = _fileExtension ?? 'file';
      return 'file_${fileId ?? 'unknown'}.$extension';
    }
    return 'file.${_fileExtension ?? 'unknown'}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.attach_file, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fieldLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getFileName(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          if (_fileExtension != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Расширение: $_fileExtension',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isLoading && _currentUrl != null) ...[
                      IconButton(
                        icon: const Icon(Icons.open_in_new, color: Colors.blue),
                        onPressed: _openFile,
                        tooltip: 'Открыть файл',
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        onPressed: _downloadFile,
                        tooltip: 'Скачать файл',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
