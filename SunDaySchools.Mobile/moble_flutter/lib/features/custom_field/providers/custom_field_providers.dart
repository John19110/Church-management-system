import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/custom_field_models.dart';
import '../repositories/custom_field_repository.dart';

final customFieldRepositoryProvider = Provider<CustomFieldRepository>((ref) {
  return CustomFieldRepository(ref.watch(dioProvider));
});

final customFieldDefinitionsProvider =
    FutureProvider.family<List<CustomFieldDefinitionReadDto>, String>(
  (ref, entityName) async {
    ref.watch(authSessionEpochProvider);
    return ref
        .read(customFieldRepositoryProvider)
        .getDefinitions(entityName, includeInactive: false);
  },
);

final entityCustomFieldsProvider =
    FutureProvider.family<EntityCustomFieldsReadDto, ({String entity, int id})>(
  (ref, params) async {
    ref.watch(authSessionEpochProvider);
    return ref.read(customFieldRepositoryProvider).getEntityFields(
          params.entity,
          params.id,
        );
  },
);
