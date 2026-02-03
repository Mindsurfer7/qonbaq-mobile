import 'package:flutter/material.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';

/// Переиспользуемый виджет для выпадающего списка с возможностью поиска
/// 
/// Если элементов <= 5, показывает обычный DropdownButtonFormField
/// Если элементов > 5, показывает кнопку, которая открывает модальное окно с поиском
class SearchableDropdown<T> extends StatelessWidget {
  /// Текущее выбранное значение
  final T? value;

  /// Список всех опций
  final List<T> items;

  /// Функция для получения текстового представления элемента
  final String Function(T) getDisplayText;

  /// Функция для получения дополнительного текста (например, роль)
  final String? Function(T)? getSubtitleText;

  /// Callback при выборе элемента
  final void Function(T?) onChanged;

  /// Заголовок поля
  final String? labelText;

  /// Обязательное поле
  final bool required;

  /// Валидатор
  final String? Function(T?)? validator;

  /// Порог количества элементов для показа поиска (по умолчанию 5)
  final int searchThreshold;

  /// Функция для фильтрации элементов по поисковому запросу
  /// По умолчанию ищет по getDisplayText
  final bool Function(T, String)? filterFunction;

  /// Виджет для отображения элемента в списке
  final Widget Function(BuildContext, T)? itemBuilder;

  /// Режим автоматической валидации
  final AutovalidateMode autovalidateMode;

  const SearchableDropdown({
    super.key,
    this.value,
    required this.items,
    required this.getDisplayText,
    this.getSubtitleText,
    required this.onChanged,
    this.labelText,
    this.required = false,
    this.validator,
    this.searchThreshold = 5,
    this.filterFunction,
    this.itemBuilder,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  @override
  Widget build(BuildContext context) {
    // Если элементов меньше или равно порогу, используем обычный dropdown
    if (items.length <= searchThreshold) {
      return _buildStandardDropdown(context);
    }

    // Если элементов больше порога, используем кнопку с модальным окном поиска
    return _buildSearchableButton(context);
  }

  /// Обычный DropdownButtonFormField для небольшого количества элементов
  Widget _buildStandardDropdown(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText != null
            ? labelText! + (required ? ' *' : '')
            : null,
        border: const OutlineInputBorder(),
      ),
      isDense: true,
      dropdownColor: context.appTheme.backgroundSurface,
      borderRadius: BorderRadius.circular(context.appTheme.borderRadius),
      autovalidateMode: autovalidateMode,
      selectedItemBuilder: (BuildContext context) {
        return items.map<Widget>((T item) {
          return Text(
            getDisplayText(item),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        }).toList();
      },
      items: items.map((T item) {
        return createStyledDropdownItem<T>(
          context: context,
          value: item,
          child: itemBuilder != null
              ? itemBuilder!(context, item)
              : _buildDefaultItem(context, item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Кнопка, которая открывает модальное окно с поиском
  Widget _buildSearchableButton(BuildContext context) {
    final errorText = validator?.call(value);
    return InkWell(
      onTap: () => _showSearchDialog(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText != null
              ? labelText! + (required ? ' *' : '')
              : null,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          errorText: errorText,
        ),
        child: Text(
          value != null ? getDisplayText(value as T) : '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }

  /// Показывает модальное окно с поиском
  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchDialog<T>(
        items: items,
        selectedValue: value,
        getDisplayText: getDisplayText,
        getSubtitleText: getSubtitleText,
        filterFunction: filterFunction,
        itemBuilder: itemBuilder,
        onItemSelected: (item) {
          Navigator.of(context).pop();
          onChanged(item);
        },
      ),
    );
  }

  /// Виджет по умолчанию для элемента списка
  Widget _buildDefaultItem(BuildContext context, T item) {
    final subtitle = getSubtitleText?.call(item);
    if (subtitle != null && subtitle.isNotEmpty) {
      return SizedBox(
        height: 48,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                getDisplayText(item),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      getDisplayText(item),
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Модальное окно с поиском
class _SearchDialog<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedValue;
  final String Function(T) getDisplayText;
  final String? Function(T)? getSubtitleText;
  final bool Function(T, String)? filterFunction;
  final Widget Function(BuildContext, T)? itemBuilder;
  final void Function(T?) onItemSelected;

  const _SearchDialog({
    required this.items,
    this.selectedValue,
    required this.getDisplayText,
    this.getSubtitleText,
    this.filterFunction,
    this.itemBuilder,
    required this.onItemSelected,
  });

  @override
  State<_SearchDialog<T>> createState() => _SearchDialogState<T>();
}

class _SearchDialogState<T> extends State<_SearchDialog<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          if (widget.filterFunction != null) {
            return widget.filterFunction!(item, query);
          }
          // По умолчанию ищем по основному тексту
          return widget.getDisplayText(item).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.backgroundSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Заголовок и поле поиска
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Индикатор перетаскивания
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Поле поиска
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Поиск...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(theme.borderRadius),
                            ),
                            filled: true,
                            fillColor: theme.backgroundSurface,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Список элементов
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'Ничего не найдено',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = widget.selectedValue == item;
                          return InkWell(
                            onTap: () => widget.onItemSelected(item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.backgroundActive
                                    : null,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: widget.itemBuilder != null
                                  ? widget.itemBuilder!(context, item)
                                  : _buildDefaultItem(context, item),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultItem(BuildContext context, T item) {
    final subtitle = widget.getSubtitleText?.call(item);
    if (subtitle != null && subtitle.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.getDisplayText(item),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }
    return Text(
      widget.getDisplayText(item),
      style: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
    );
  }
}

