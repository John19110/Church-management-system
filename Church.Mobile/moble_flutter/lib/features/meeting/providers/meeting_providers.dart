import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/cache_providers.dart';
import '../../../core/models/select_option.dart';
import '../models/meeting_models.dart';
import '../repositories/meeting_repository.dart';

final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(dioProvider), ref.watch(cacheManagerProvider));
});

final meetingsForSelectionProvider =
    FutureProvider<List<SelectOption>>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  if (!await hasStoredAuthToken()) return const [];
  return ref.watch(meetingRepositoryProvider).getForSelection();
});

final visibleMeetingsProvider = FutureProvider<List<MeetingReadDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return whenAuthenticated(
    () => ref.watch(meetingRepositoryProvider).getVisibleMeetings(),
    ifLoggedOut: const [],
  );
});

/// Cache-first meetings (tenant + role aware).
final visibleMeetingsCacheFirstProvider =
    StreamProvider<List<MeetingReadDto>>((ref) async* {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  final tenantId = await ref.watch(currentChurchIdProvider.future) ?? 0;
  final role = (await ref.watch(currentUserRoleProvider.future)) ?? '';
  if (tenantId <= 0 || role.isEmpty) {
    yield const <MeetingReadDto>[];
    return;
  }
  yield* ref
      .watch(meetingRepositoryProvider)
      .watchVisibleMeetingsCacheFirst(tenantId: tenantId, role: role);
});
