import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/models/select_option.dart';
import '../../unified_form/models/unified_form_models.dart';
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
  ref.watch(authStateProvider);
  return whenAuthenticated(
    () => ref.watch(servantsRepositoryProvider).getForSelection(),
    ifLoggedOut: const [],
  );
});

final servantProfileProvider = FutureProvider<ServantProfileDto>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  if (!await hasStoredAuthToken()) {
    throw const UnauthorizedException();
  }
  return ref.watch(servantsRepositoryProvider).getProfile();
});

final servantProfileFormDataProvider = FutureProvider<EntityFormDataDto>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  if (!await hasStoredAuthToken()) {
    throw const UnauthorizedException();
  }
  return ref.watch(servantsRepositoryProvider).getProfileFormData();
});
