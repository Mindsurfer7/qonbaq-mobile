/// Информация об отсутствующей роли
class MissingRoleInfo {
  final String roleCode;
  final String roleName;
  final List<AffectedTemplateInfo> affectedTemplates;

  MissingRoleInfo({
    required this.roleCode,
    required this.roleName,
    required this.affectedTemplates,
  });
}

/// Информация о шаблоне, затронутом отсутствующей ролью
class AffectedTemplateInfo {
  final String id;
  final String name;
  final String code;

  AffectedTemplateInfo({
    required this.id,
    required this.name,
    required this.code,
  });
}
