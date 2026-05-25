import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
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
    ref.watch(authStateProvider);
    return whenAuthenticated(
      () => ref
          .read(customFieldRepositoryProvider)
          .getDefinitions(entityName, includeInactive: false),
      ifLoggedOut: const [],
    );
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
