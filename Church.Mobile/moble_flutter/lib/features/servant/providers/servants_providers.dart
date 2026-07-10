import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/cache_providers.dart';
import '../../../core/models/select_option.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../models/servant_models.dart';
import '../repositories/servants_repository.dart';

final servantsRepositoryProvider = Provider((ref) {
  return ServantsRepository(ref.watch(dioProvider), ref.watch(cacheManagerProvider));
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

final servantProfileCacheFirstProvider =
    StreamProvider<ServantProfileDto>((ref) async* {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  final tenantId = await ref.watch(currentChurchIdProvider.future) ?? 0;
  final userId = (await ref.watch(currentUserIdProvider.future)) ?? '';
  if (tenantId <= 0 || userId.isEmpty) {
    throw const UnauthorizedException();
  }
  yield* ref
      .watch(servantsRepositoryProvider)
      .watchProfileCacheFirst(tenantId: tenantId, userId: userId);
});

/// Servants belonging to a specific meeting — used by the meeting-scoped list screen.
final servantsByMeetingProvider =
    FutureProvider.family<List<ServantReadDto>, int>((ref, meetingId) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return ref.watch(servantsRepositoryProvider).getByMeeting(meetingId);
});

final servantProfileFormDataProvider = FutureProvider<EntityFormDataDto>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  if (!await hasStoredAuthToken()) {
    throw const UnauthorizedException();
  }
  return ref.watch(servantsRepositoryProvider).getProfileFormData();
});
