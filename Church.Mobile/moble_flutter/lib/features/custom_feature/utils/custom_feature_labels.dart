import '../../../core/l10n/app_localizations.dart';
import '../models/custom_feature_models.dart';

String featureDisplayName(CustomFeatureReadDto feature, AppLocalizations l10n) {
  final isArabic = l10n.locale.languageCode == 'ar';
  if (isArabic && (feature.displayNameAr?.trim().isNotEmpty ?? false)) {
    return feature.displayNameAr!.trim();
  }
  return feature.displayName;
}

String entityDisplayName(CustomEntityReadDto entity, AppLocalizations l10n) {
  final isArabic = l10n.locale.languageCode == 'ar';
  if (isArabic && (entity.displayNameAr?.trim().isNotEmpty ?? false)) {
    return entity.displayNameAr!.trim();
  }
  return entity.displayName;
}

String entityPluralName(CustomEntityReadDto entity, AppLocalizations l10n) {
  final isArabic = l10n.locale.languageCode == 'ar';
  if (isArabic && (entity.pluralDisplayNameAr?.trim().isNotEmpty ?? false)) {
    return entity.pluralDisplayNameAr!.trim();
  }
  if (entity.pluralDisplayName.trim().isNotEmpty) {
    return entity.pluralDisplayName;
  }
  return entityDisplayName(entity, l10n);
}

String fieldTypeKey(CustomEntityFieldType type) {
  final name = type.apiName;
  return name[0].toLowerCase() + name.substring(1);
}

String fieldDisplayName(CustomEntityFieldReadDto field, AppLocalizations l10n) {
  final isArabic = l10n.locale.languageCode == 'ar';
  if (isArabic && (field.displayNameAr?.trim().isNotEmpty ?? false)) {
    return field.displayNameAr!.trim();
  }
  return field.displayName;
}

String optionDisplayText(CustomFeatureOptionDto option, AppLocalizations l10n) {
  final isArabic = l10n.locale.languageCode == 'ar';
  if (isArabic && (option.displayTextAr?.trim().isNotEmpty ?? false)) {
    return option.displayTextAr!.trim();
  }
  return option.displayText;
}

String recordTitle(
  CustomEntityRecordReadDto record,
  CustomEntityReadDto entity,
  AppLocalizations l10n,
) {
  for (final field in entity.fields.where((f) => f.showOnList)) {
    final value = formatRecordValue(record, field, l10n);
    if (value.isNotEmpty) return value;
  }
  return '${entityDisplayName(entity, l10n)} #${record.id}';
}

String formatRecordValue(
  CustomEntityRecordReadDto record,
  CustomEntityFieldReadDto field,
  AppLocalizations l10n,
) {
  final label = record.values['${field.name}Label'];
  if (label != null && label.toString().trim().isNotEmpty) {
    return label.toString();
  }
  final value = record.values[field.name];
  if (value == null) return '';
  if (value is bool) return value ? l10n.yes : l10n.no;
  if (value is List) return value.map((e) => e.toString()).join(', ');
  return value.toString();
}
