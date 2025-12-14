import 'dart:convert';
import 'package:flutter/services.dart';

class RoutesConfig {
  static RoutesConfig? _instance;
  Map<String, dynamic>? _routesData;

  RoutesConfig._();

  static RoutesConfig get instance {
    _instance ??= RoutesConfig._();
    return _instance!;
  }

  Future<void> loadRoutes() async {
    if (_routesData != null) return;

    final String jsonString = await rootBundle.loadString('routes.json');
    _routesData = json.decode(jsonString) as Map<String, dynamic>;
  }

  Map<String, dynamic>? get routesData => _routesData;

  String? getMainEntryPoint() {
    return _routesData?['app']?['main_entry_point'] as String?;
  }

  List<dynamic>? getRoutes() {
    return _routesData?['app']?['routes'] as List<dynamic>?;
  }

  Map<String, dynamic>? findRouteByPath(String path) {
    final routes = getRoutes();
    if (routes == null) return null;

    for (var route in routes) {
      if (route['path'] == path) {
        return route as Map<String, dynamic>;
      }

      // Проверяем вложенные маршруты в блоках
      if (route['blocks'] != null) {
        final blocks = route['blocks'] as List<dynamic>;
        for (var block in blocks) {
          if (block['path'] == path) {
            return block as Map<String, dynamic>;
          }

          // Проверяем items в блоке
          if (block['items'] != null) {
            final items = block['items'] as List<dynamic>;
            for (var item in items) {
              if (item['path'] == path) {
                return item as Map<String, dynamic>;
              }

              // Проверяем sub_items
              if (item['sub_items'] != null) {
                final subItems = item['sub_items'] as List<dynamic>;
                for (var subItem in subItems) {
                  if (subItem['path'] == path) {
                    return subItem as Map<String, dynamic>;
                  }

                  // Проверяем nested
                  if (subItem['nested'] != null) {
                    final nested = subItem['nested'] as List<dynamic>;
                    for (var nestedItem in nested) {
                      if (nestedItem['path'] == path) {
                        return nestedItem as Map<String, dynamic>;
                      }

                      // Проверяем further_nesting
                      if (nestedItem['further_nesting'] != null) {
                        final further =
                            nestedItem['further_nesting'] as List<dynamic>;
                        for (var furtherItem in further) {
                          if (furtherItem['path'] == path) {
                            return furtherItem as Map<String, dynamic>;
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Проверяем nested напрямую в items
              if (item['nested'] != null) {
                final nested = item['nested'] as List<dynamic>;
                for (var nestedItem in nested) {
                  if (nestedItem['path'] == path) {
                    return nestedItem as Map<String, dynamic>;
                  }

                  // Проверяем further_nesting
                  if (nestedItem['further_nesting'] != null) {
                    final further =
                        nestedItem['further_nesting'] as List<dynamic>;
                    for (var furtherItem in further) {
                      if (furtherItem['path'] == path) {
                        return furtherItem as Map<String, dynamic>;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      // Проверяем common_navigation
      if (route['common_navigation'] != null) {
        final nav = route['common_navigation'] as List<dynamic>;
        for (var navItem in nav) {
          if (navItem['path'] == path) {
            return navItem as Map<String, dynamic>;
          }
        }
      }

      // Проверяем main_menu_sections
      if (route['main_menu_sections'] != null) {
        final sections = route['main_menu_sections'] as List<dynamic>;
        for (var section in sections) {
          if (section['path'] == path) {
            return section as Map<String, dynamic>;
          }
        }
      }
    }

    return null;
  }
}



