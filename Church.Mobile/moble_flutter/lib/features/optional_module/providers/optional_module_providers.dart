import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../models/optional_module_models.dart';
import '../repositories/optional_module_repository.dart';

final optionalModuleRepositoryProvider = Provider((ref) {
  return OptionalModuleRepository(ref.watch(dioProvider));
});

final stockItemRepositoryProvider = Provider((ref) {
  return StockItemRepository(ref.watch(dioProvider));
});

final optionalModulesRevisionProvider = StateProvider<int>((ref) => 0);
final stockItemsRevisionProvider = StateProvider<int>((ref) => 0);

void bumpOptionalModules(WidgetRef ref) {
  ref.read(optionalModulesRevisionProvider.notifier).state++;
}

void bumpStockItems(WidgetRef ref) {
  ref.read(stockItemsRevisionProvider.notifier).state++;
}

final optionalModulesProvider =
    FutureProvider<List<OptionalModuleDto>>((ref) async {
  ref.watch(optionalModulesRevisionProvider);
  ref.watch(authSessionEpochProvider);
  return ref.read(optionalModuleRepositoryProvider).getModules();
});

final enabledOptionalModulesProvider =
    Provider<AsyncValue<List<OptionalModuleDto>>>((ref) {
  return ref.watch(optionalModulesProvider).whenData(
        (modules) => modules.where((m) => m.isEnabled).toList(),
      );
});

final isStockModuleEnabledProvider = Provider<AsyncValue<bool>>((ref) {
  return ref.watch(optionalModulesProvider).whenData(
        (modules) => modules.any(
          (m) => m.id == OptionalModuleIds.stock && m.isEnabled,
        ),
      );
});

final stockItemsProvider =
    FutureProvider.family<List<StockItemDto>, String>((ref, search) async {
  ref.watch(stockItemsRevisionProvider);
  ref.watch(authSessionEpochProvider);
  return ref.read(stockItemRepositoryProvider).getItems(search: search);
});

final stockItemProvider =
    FutureProvider.family<StockItemDto, int>((ref, id) async {
  ref.watch(stockItemsRevisionProvider);
  return ref.read(stockItemRepositoryProvider).getItem(id);
});
