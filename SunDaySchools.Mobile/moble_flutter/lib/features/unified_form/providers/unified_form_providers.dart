import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/unified_form_models.dart';
import '../repositories/unified_form_repository.dart';

final unifiedFormRepositoryProvider = Provider<UnifiedFormRepository>((ref) {
  return UnifiedFormRepository(ref.watch(dioProvider));
});

final entityFormSchemaProvider =
    FutureProvider.family<EntityFormSchemaDto, ({String entity, String mode})>(
  (ref, params) async {
    ref.watch(authSessionEpochProvider);
    return ref.read(unifiedFormRepositoryProvider).getFormSchema(
          params.entity,
          mode: params.mode,
        );
  },
);

final entityFormDataProvider =
    FutureProvider.family<EntityFormDataDto, ({String entity, int id})>(
  (ref, params) async {
    ref.watch(authSessionEpochProvider);
    return ref.read(unifiedFormRepositoryProvider).getFormData(
          params.entity,
          params.id,
        );
  },
);
