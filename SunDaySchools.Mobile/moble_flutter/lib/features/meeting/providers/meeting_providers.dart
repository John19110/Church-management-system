import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/models/select_option.dart';
import '../models/meeting_models.dart';
import '../repositories/meeting_repository.dart';

final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(dioProvider));
});

final meetingsForSelectionProvider =
    FutureProvider<List<SelectOption>>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return whenAuthenticated(
    () => ref.watch(meetingRepositoryProvider).getForSelection(),
    ifLoggedOut: const [],
  );
});

final visibleMeetingsProvider = FutureProvider<List<MeetingReadDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  ref.watch(authStateProvider);
  return whenAuthenticated(
    () => ref.watch(meetingRepositoryProvider).getVisibleMeetings(),
    ifLoggedOut: const [],
  );
});
