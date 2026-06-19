import '../models/unified_form_models.dart';
import 'unified_form_controller.dart';

/// Tracks field list changes so forms re-bind after admin adds custom attributes.
mixin UnifiedFormScreenMixin {
  String _fieldListSignature = '';

  String fieldListSignature(List<UnifiedFieldDefinitionDto> fields) =>
      fields.map((f) => '${f.fieldKey}:${f.customFieldDefinitionId}').join('|');

  String fieldValueSignature(List<UnifiedFieldDto> fields) =>
      fields.map((f) => '${f.fieldKey}:${f.value ?? ''}').join('|');

  void syncFormController(
    UnifiedFormController controller,
    List<UnifiedFieldDefinitionDto> fields, {
    List<UnifiedFieldDto>? withValues,
  }) {
    final valueFields = withValues ?? const <UnifiedFieldDto>[];
    final sig = '${fieldListSignature(fields)}|${fieldValueSignature(valueFields)}';
    if (sig == _fieldListSignature) return;
    _fieldListSignature = sig;
    controller.initializeFromFields(fields, withValues: withValues);
  }

  void resetFormSignature() => _fieldListSignature = '';
}
