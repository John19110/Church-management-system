import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';

extension CustomFieldL10n on AppLocalizations {
  String labelForDataType(CustomFieldDataType type) {
    switch (type) {
      case CustomFieldDataType.text:
        return customFieldDataTypeLabel('text');
      case CustomFieldDataType.longText:
        return customFieldDataTypeLabel('longText');
      case CustomFieldDataType.number:
        return customFieldDataTypeLabel('number');
      case CustomFieldDataType.decimal:
        return customFieldDataTypeLabel('decimal');
      case CustomFieldDataType.boolean:
        return customFieldDataTypeLabel('boolean');
      case CustomFieldDataType.date:
        return customFieldDataTypeLabel('date');
      case CustomFieldDataType.dateTime:
        return customFieldDataTypeLabel('dateTime');
      case CustomFieldDataType.json:
        return customFieldDataTypeLabel('json');
      case CustomFieldDataType.singleSelect:
        return customFieldDataTypeLabel('singleSelect');
      case CustomFieldDataType.multiSelect:
        return customFieldDataTypeLabel('multiSelect');
      case CustomFieldDataType.unknown:
        return customFieldDataTypeLabel('text');
    }
  }
}
