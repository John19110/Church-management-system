import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/models/select_option.dart';
import '../models/servant_models.dart';
import '../repositories/servants_repository.dart';

final servantsRepositoryProvider = Provider((ref) {
  return ServantsRepository(ref.watch(dioProvider));
});

final servantsListProvider = FutureProvider<List<ServantReadDto>>((ref) async {
  return ref.watch(servantsRepositoryProvider).getAll();
});

final servantDetailProvider =
    FutureProvider.family<ServantReadDto, int>((ref, id) async {
  return ref.watch(servantsRepositoryProvider).getById(id);
});

final servantsForSelectionProvider = FutureProvider<List<SelectOption>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(servantsRepositoryProvider).getForSelection();
});
