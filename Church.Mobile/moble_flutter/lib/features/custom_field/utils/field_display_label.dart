import 'package:flutter/material.dart';

import '../../../core/field_labels/system_field_labels.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../unified_form/models/unified_form_models.dart';
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

/// Shared resolver for all custom/system field labels in the UI.
String resolveFieldDisplayLabel({
  required String fieldKey,
  required String displayName,
  String? displayNameAr,
  required AppLocalizations l10n,
  String? entityName,
  bool isBuiltIn = false,
}) {
  final en = displayName.trim();
  final ar = (displayNameAr ?? '').trim();
  final isArabic = l10n.locale.languageCode == 'ar';

  final system = entityName != null
      ? systemFieldLabel(l10n, entityName, fieldKey)
      : null;
  final hasSystem = system != null && system.isNotEmpty;

  if (isArabic) {
    if (ar.isNotEmpty) return ar;
    if (isBuiltIn && hasSystem) return system;
    if (en.isNotEmpty) return en;
    if (hasSystem) return system;
  } else {
    if (en.isNotEmpty) return en;
    if (isBuiltIn && hasSystem) return system;
    if (ar.isNotEmpty) return ar;
    if (hasSystem) return system;
  }

  return fieldKey;
}

/// User-facing label for a field definition (system or custom).
String localizedFieldDisplayLabel(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  return resolveFieldDisplayLabel(
    fieldKey: definition.name,
    displayName: definition.displayName,
    displayNameAr: definition.displayNameAr,
    l10n: l10n,
    entityName: definition.entityName,
    isBuiltIn: definition.isBuiltIn || definition.isSystemField,
  );
}

/// User-facing label for unified form/detail field metadata.
String unifiedFieldLabel(
  UnifiedFieldDefinitionDto field, {
  String? entityName,
  AppLocalizations? l10n,
}) {
  final loc = l10n ?? AppLocalizations.forLocale(const Locale('en'));
  return resolveFieldDisplayLabel(
    fieldKey: field.fieldKey,
    displayName: field.displayName,
    displayNameAr: field.displayNameAr,
    l10n: loc,
    entityName: entityName,
    isBuiltIn: field.isBuiltIn,
  );
}

int compareFieldDefinitionLabels(
  CustomFieldDefinitionReadDto a,
  CustomFieldDefinitionReadDto b,
  AppLocalizations l10n,
) {
  return localizedFieldDisplayLabel(a, l10n)
      .compareTo(localizedFieldDisplayLabel(b, l10n));
}

int compareUnifiedFieldLabels(
  UnifiedFieldDefinitionDto a,
  UnifiedFieldDefinitionDto b,
  AppLocalizations l10n, {
  String? entityName,
}) {
  return unifiedFieldLabel(a, entityName: entityName, l10n: l10n)
      .compareTo(unifiedFieldLabel(b, entityName: entityName, l10n: l10n));
}

/// Subtitle line for admin field cards (type + status; no raw backend keys).
String localizedFieldCardSubtitle(
  CustomFieldDefinitionReadDto definition,
  AppLocalizations l10n,
) {
  return l10n.labelForDataType(definition.dataType);
}
