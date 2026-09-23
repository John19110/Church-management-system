import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/custom_feature_models.dart';
import '../repositories/custom_feature_repository.dart';

final customFeatureRepositoryProvider = Provider((ref) {
  return CustomFeatureRepository(ref.watch(dioProvider));
});

final customFeaturesRevisionProvider = StateProvider<int>((ref) => 0);

final customFeaturesProvider =
    FutureProvider.family<List<CustomFeatureReadDto>, bool>((
  ref,
  includeInactive,
) async {
  ref.watch(customFeaturesRevisionProvider);
  ref.watch(authSessionEpochProvider);
  return ref
      .read(customFeatureRepositoryProvider)
      .getFeatures(includeInactive: includeInactive);
});

final customFeatureProvider =
    FutureProvider.family<CustomFeatureReadDto, int>((ref, id) async {
  ref.watch(customFeaturesRevisionProvider);
  return ref.read(customFeatureRepositoryProvider).getFeature(id);
});

final customEntityProvider =
    FutureProvider.family<CustomEntityReadDto, int>((ref, id) async {
  ref.watch(customFeaturesRevisionProvider);
  return ref.read(customFeatureRepositoryProvider).getEntity(id);
});

class CustomRecordListKey {
  final int entityId;
  final String search;

  const CustomRecordListKey(this.entityId, this.search);

  @override
  bool operator ==(Object other) =>
      other is CustomRecordListKey &&
      other.entityId == entityId &&
      other.search == search;

  @override
  int get hashCode => Object.hash(entityId, search);
}

final customRecordsProvider =
    FutureProvider.family<CustomEntityRecordPageDto, CustomRecordListKey>((
  ref,
  key,
) async {
  ref.watch(customFeaturesRevisionProvider);
  return ref.read(customFeatureRepositoryProvider).getRecords(
        entityId: key.entityId,
        search: key.search,
        page: 1,
        pageSize: 20,
      );
});

final customRecordProvider =
    FutureProvider.family<CustomEntityRecordReadDto, (int, int)>((
  ref,
  ids,
) async {
  ref.watch(customFeaturesRevisionProvider);
  return ref.read(customFeatureRepositoryProvider).getRecord(
        entityId: ids.$1,
        recordId: ids.$2,
      );
});

void bumpCustomFeatures(WidgetRef ref) {
  ref.read(customFeaturesRevisionProvider.notifier).state++;
}
