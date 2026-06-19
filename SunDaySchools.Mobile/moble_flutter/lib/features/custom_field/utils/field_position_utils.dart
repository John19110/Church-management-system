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

int positionOptionCount({
  required bool isCreate,
  required List<CustomFieldDefinitionReadDto> sortedActive,
}) {
  final activeCount = sortedActive.length;
  if (isCreate) {
    return activeCount + 1;
  }
  return activeCount > 0 ? activeCount : 1;
}

int clampFieldPosition(int position, int positionCount) =>
    position.clamp(1, positionCount);

int currentFieldPosition(
  CustomFieldDefinitionReadDto field,
  List<CustomFieldDefinitionReadDto> sortedActive,
) {
  final index = sortedActive.indexWhere((d) => d.id == field.id);
  if (index >= 0) {
    return index + 1;
  }

  if (sortedActive.isEmpty) {
    return 1;
  }

  final rank =
      sortedActive.where((d) => d.sortOrder < field.sortOrder).length + 1;
  return rank.clamp(1, sortedActive.length);
}

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
