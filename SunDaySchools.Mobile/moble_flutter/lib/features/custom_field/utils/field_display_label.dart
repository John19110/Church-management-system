import '../../../core/field_labels/system_field_labels.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import 'custom_field_l10n.dart';

/// Picks English or Arabic display text with cross-language fallback.
String localizedDisplayNamePair({
  required String? displayName,
  required String? displayNameAr,
  required AppLocalizations l10n,
  required String fallbackKey,
}) {
  final en = displayName?.trim() ?? '';
  final ar = displayNameAr?.trim() ?? '';
  final isArabic = l10n.locale.languageCode == 'ar';

  if (isArabic) {
    if (ar.isNotEmpty) return ar;
    if (en.isNotEmpty) return en;
  } else {
    if (en.isNotEmpty) return en;
    if (ar.isNotEmpty) return ar;
  }

  return fallbackKey;
}

/// User-facing label for a field definition (system or custom).
String localizedFieldDisplayLabel(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  if (definition.id > 0) {
    return localizedDisplayNamePair(
      displayName: definition.displayName,
      displayNameAr: definition.displayNameAr,
      l10n: l10n,
      fallbackKey: definition.name,
    );
  }

  final isSystem = definition.isBuiltIn || definition.isSystemField;
  if (isSystem) {
    final mapped = systemFieldLabel(
      l10n,
      definition.entityName,
      definition.name,
    );
    if (mapped != null && mapped.isNotEmpty) return mapped;
  }

  return localizedDisplayNamePair(
    displayName: definition.displayName,
    displayNameAr: definition.displayNameAr,
    l10n: l10n,
    fallbackKey: definition.name,
  );
}

/// Subtitle line for admin field cards (type + status; no raw backend keys).
String localizedFieldCardSubtitle(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  return l10n.labelForDataType(definition.dataType);
}
