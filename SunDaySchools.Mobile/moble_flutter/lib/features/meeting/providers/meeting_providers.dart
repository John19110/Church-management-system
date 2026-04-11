import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../features/classroom/models/classroom_models.dart';
import '../models/meeting_models.dart';
import '../repositories/meeting_repository.dart';

final meetingRepositoryProvider = Provider((ref) {
  return MeetingRepository(ref.watch(dioProvider));
});

final meetingsForSelectionProvider =
    FutureProvider<List<SelectOptionDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(meetingRepositoryProvider).getForSelection();
});

final visibleMeetingsProvider = FutureProvider<List<MeetingReadDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(meetingRepositoryProvider).getVisibleMeetings();
});
