import 'package:flutter/material.dart';
import '../../core/utils/dropdown_helpers.dart';
import '../../core/theme/theme_extensions.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

/// Переиспользуемый виджет для выбора компании
/// Использует ProfileProvider для получения списка компаний
class BusinessSelectorWidget extends StatelessWidget {
  /// Компактный режим (для использования в карточках/плашках)
  final bool compact;

  /// Показывать заголовок
  final bool showTitle;

  const BusinessSelectorWidget({
    super.key,
    this.compact = false,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        // Если компании еще не загружены - загружаем
        if (provider.businesses == null && !provider.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadBusinesses();
          });
        }

        // Загрузка
        if (provider.isLoading) {
          return compact
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const Center(child: CircularProgressIndicator());
        }

        // Ошибка
        if (provider.error != null) {
          return compact
              ? _buildCompactError(provider)
              : _buildFullError(provider);
        }

        // Нет компаний
        if (provider.businesses == null || provider.businesses!.isEmpty) {
          return compact
              ? _buildCompactNoBusinesses()
              : _buildFullNoBusinesses();
        }

        // Компания уже выбрана - не показываем виджет
        if (provider.selectedBusiness != null) {
          return const SizedBox.shrink();
        }

        // Показываем селектор
        return compact
            ? _buildCompactSelector(provider, context)
            : _buildFullSelector(provider, context);
      },
    );
  }

  Widget _buildCompactError(ProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 4),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => provider.loadBusinesses(),
            child: const Text('Повторить', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFullError(ProfileProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            provider.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadBusinesses(),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactNoBusinesses() {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Center(
        child: Text(
          'Нет доступных компаний',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFullNoBusinesses() {
    return const Center(
      child: Text('Нет доступных компаний'),
    );
  }

  Widget _buildCompactSelector(ProfileProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            const Text(
              'Выберите компанию',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          if (showTitle) const SizedBox(height: 8),
          DropdownButtonFormField(
            value: provider.selectedBusiness,
            decoration: const InputDecoration(
              labelText: 'Компания',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            isExpanded: true,
            dropdownColor: context.appTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(context.appTheme.borderRadius),
            selectedItemBuilder: (BuildContext context) {
              return provider.businesses!.map<Widget>((business) {
                return Text(
                  business.name,
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
            items: provider.businesses!
                .map(
                  (business) => createStyledDropdownItem(
                    context: context,
                    value: business,
                    child: Text(
                      business.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (business) {
              if (business != null) {
                provider.selectBusiness(business);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullSelector(ProfileProvider provider, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTitle)
            const Text(
              'Выберите компанию',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (showTitle) const SizedBox(height: 16),
          DropdownButtonFormField(
            value: provider.selectedBusiness,
            decoration: const InputDecoration(
              labelText: 'Выберите компанию',
              border: OutlineInputBorder(),
            ),
            dropdownColor: context.appTheme.backgroundSurface,
            borderRadius: BorderRadius.circular(context.appTheme.borderRadius),
            selectedItemBuilder: (BuildContext context) {
              return provider.businesses!.map<Widget>((business) {
                return Text(business.name);
              }).toList();
            },
            items: provider.businesses!
                .map(
                  (business) => createStyledDropdownItem(
                    context: context,
                    value: business,
                    child: Text(business.name),
                  ),
                )
                .toList(),
            onChanged: (business) {
              if (business != null) {
                provider.selectBusiness(business);
              }
            },
          ),
        ],
      ),
    );
  }
}

