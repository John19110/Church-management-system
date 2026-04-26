import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/models/select_option.dart';
import '../models/classroom_models.dart';
import '../repositories/classroom_repository.dart';

final classroomRepositoryProvider = Provider((ref) {
  return ClassroomRepository(ref.watch(dioProvider));
});

final visibleClassroomsProvider =
    FutureProvider<List<ClassroomReadDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(classroomRepositoryProvider).getVisible();
});

final visibleClassroomsByMeetingProvider =
    FutureProvider.family<List<ClassroomReadDto>, int?>((ref, meetingId) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(classroomRepositoryProvider).getVisible(meetingId: meetingId);
});

final classroomsForSelectionProvider =
    FutureProvider<List<SelectOption>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(classroomRepositoryProvider).getForSelection();
});
