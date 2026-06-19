import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';

/// Active provisioned fields sorted for appearance position UI.
List<CustomFieldDefinitionReadDto> sortedActiveProvisionedFields(
  Iterable<CustomFieldDefinitionReadDto> fields,
) {
  final list = fields.where((d) => d.isActive && d.id > 0).toList()
    ..sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order != 0 ? order : a.displayName.compareTo(b.displayName);
    });
  return list;
}

int currentFieldPosition(
  CustomFieldDefinitionReadDto field,
  List<CustomFieldDefinitionReadDto> sortedActive,
) {
  final index = sortedActive.indexWhere((d) => d.id == field.id);
  return index < 0 ? sortedActive.length + 1 : index + 1;
}

int positionOptionCount({
  required bool isCreate,
  required List<CustomFieldDefinitionReadDto> sortedActive,
}) =>
    isCreate ? sortedActive.length + 1 : sortedActive.length;

String fieldAppearancePositionLabel(
  AppLocalizations l10n,
  int position, {
  required int total,
}) {
  if (position == total && total > 1) {
    return l10n.fieldPositionLast;
  }
  return l10n.fieldPositionOrdinal(position);
}
