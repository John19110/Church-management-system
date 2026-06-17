import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../unified_form/providers/unified_form_providers.dart';
import 'custom_field_providers.dart';
import 'custom_field_revision_provider.dart';

/// Call after any custom field definition change for [entityName].
void refreshEntityFormsAfterDefinitionChange(
  WidgetRef ref,
  String entityName,
) {
  ref.read(customFieldDefinitionsRevisionProvider(entityName).notifier).state++;
  ref.invalidate(
    customFieldDefinitionsProvider((
      entityName: entityName,
      includeInactive: true,
    )),
  );
  ref.invalidate(
    customFieldDefinitionsProvider((
      entityName: entityName,
      includeInactive: false,
    )),
  );
  ref.invalidate(entityFormSchemaProvider);
  ref.invalidate(entityFormDataProvider);
  ref.invalidate(entityCustomFieldsProvider);
}
