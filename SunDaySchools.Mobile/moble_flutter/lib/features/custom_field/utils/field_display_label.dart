import '../../../core/field_labels/system_field_labels.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import 'custom_field_l10n.dart';

/// User-facing label for a field definition (system or custom).
String localizedFieldDisplayLabel(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  final isSystem = definition.isBuiltIn || definition.isSystemField;
  if (isSystem) {
    final mapped = systemFieldLabel(
      l10n,
      definition.entityName,
      definition.name,
    );
    if (mapped != null && mapped.isNotEmpty) return mapped;
  }
  return definition.displayName.trim().isNotEmpty
      ? definition.displayName
      : definition.name;
}

/// Subtitle line for admin field cards (type + status; no raw backend keys).
String localizedFieldCardSubtitle(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  return l10n.labelForDataType(definition.dataType);
}
