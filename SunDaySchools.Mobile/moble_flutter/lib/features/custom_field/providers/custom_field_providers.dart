import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/custom_field_models.dart';
import '../repositories/custom_field_repository.dart';
import '../utils/custom_field_definition_merge.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import 'custom_field_revision_provider.dart';

/// Query key for [customFieldDefinitionsProvider].
typedef CustomFieldDefinitionsQuery = ({
  String entityName,
  bool includeInactive,
});

final customFieldRepositoryProvider = Provider<CustomFieldRepository>((ref) {
  return CustomFieldRepository(ref.watch(dioProvider));
});

final customFieldDefinitionsProvider =
    FutureProvider.family<List<CustomFieldDefinitionReadDto>, CustomFieldDefinitionsQuery>(
  (ref, query) async {
    ref.watch(authSessionEpochProvider);
    ref.watch(authStateProvider);
    ref.watch(customFieldDefinitionsRevisionProvider(query.entityName));

    debugPrint(
      '[CustomFieldDefinitionsProvider] loading entity=${query.entityName} '
      'includeInactive=${query.includeInactive}',
    );

    final result = await whenAuthenticated(
      () async {
        final defs = await ref.read(customFieldRepositoryProvider).getDefinitions(
              query.entityName,
              includeInactive: query.includeInactive,
            );

        if (definitionsIncludeSystemFields(defs)) {
          return defs;
        }

        debugPrint(
          '[CustomFieldDefinitionsProvider] no system fields from definitions API; '
          'trying form-schema fallback for ${query.entityName}',
        );

        try {
          final schema = await ref
              .read(unifiedFormRepositoryProvider)
              .getFormSchema(query.entityName);
          final merged = mergeDefinitionsWithFormSchema(defs, schema);
          debugPrint(
            '[CustomFieldDefinitionsProvider] form-schema fallback merged '
            '${merged.length} field(s) (${merged.where((d) => d.isBuiltIn).length} system)',
          );
          return merged;
        } catch (e, st) {
          debugPrint(
            '[CustomFieldDefinitionsProvider] form-schema fallback failed: $e',
          );
          debugPrint(st.toString());
          return defs;
        }
      },
      ifLoggedOut: const <CustomFieldDefinitionReadDto>[],
    );

    debugPrint(
      '[CustomFieldDefinitionsProvider] loaded ${result.length} definition(s) '
      'for entity=${query.entityName}',
    );

    return result;
  },
);

final entityCustomFieldsProvider =
    FutureProvider.family<EntityCustomFieldsReadDto, ({String entity, int id})>(
  (ref, params) async {
    ref.watch(authSessionEpochProvider);
    ref.watch(authStateProvider);
    if (!await hasStoredAuthToken()) {
      throw const UnauthorizedException();
    }
    return ref.read(customFieldRepositoryProvider).getEntityFields(
          params.entity,
          params.id,
        );
  },
);
