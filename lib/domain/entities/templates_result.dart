import 'approval_template.dart';
import 'missing_role_info.dart';

/// Результат получения шаблонов с метаданными
class TemplatesResult {
  final List<ApprovalTemplate> templates;
  final List<MissingRoleInfo>? missingRoles;
  final int? totalMissing;

  TemplatesResult({
    required this.templates,
    this.missingRoles,
    this.totalMissing,
  });
}
