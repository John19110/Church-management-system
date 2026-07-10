import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/providers/cache_providers.dart';
import '../../../core/models/select_option.dart';
import '../models/member_models.dart';
import '../repositories/members_repository.dart';

final membersRepositoryProvider = Provider((ref) {
  return MembersRepository(ref.watch(dioProvider), ref.watch(cacheManagerProvider));
});

final membersListProvider = FutureProvider<List<MemberReadDto>>((ref) async {
  return ref.watch(membersRepositoryProvider).getAll();
});

final membersListCacheFirstProvider =
    StreamProvider<List<MemberReadDto>>((ref) async* {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  final tenantId = await ref.watch(currentChurchIdProvider.future) ?? 0;
  final role = (await ref.watch(currentUserRoleProvider.future)) ?? '';
  if (tenantId <= 0 || role.isEmpty) {
    yield const <MemberReadDto>[];
    return;
  }
  yield* ref
      .watch(membersRepositoryProvider)
      .watchAllCacheFirst(tenantId: tenantId, role: role);
});

final memberDetailProvider = FutureProvider.family<MemberReadDto, int>((ref, id) async {
  return ref.watch(membersRepositoryProvider).getById(id);
});

/// Members assigned to a classroom (includes photo URLs for list UI).
final membersByClassroomProvider =
    FutureProvider.family<List<MemberReadDto>, int>((ref, classroomId) async {
  return ref.watch(membersRepositoryProvider).getByClassroom(classroomId);
});

/// Members belonging to a specific meeting — used by the meeting-scoped list screen.
final membersByMeetingProvider =
    FutureProvider.family<List<MemberReadDto>, int>((ref, meetingId) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return ref.watch(membersRepositoryProvider).getByMeeting(meetingId);
});

final membersForSelectionProvider = FutureProvider<List<SelectOption>>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return whenAuthenticated(
    () => ref.watch(membersRepositoryProvider).getForSelection(),
    ifLoggedOut: const [],
  );
});
