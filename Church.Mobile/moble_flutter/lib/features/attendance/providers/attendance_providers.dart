import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/attendance_models.dart';
import '../repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

final attendanceSessionProvider =
    FutureProvider.family<AttendanceSessionReadDto, int>((ref, id) async {
  return ref.watch(attendanceRepositoryProvider).getById(id);
});

final attendanceHistoryByClassroomProvider =
    FutureProvider.family<List<AttendanceSessionSummaryDto>, int>(
        (ref, classroomId) async {
  return ref
      .watch(attendanceRepositoryProvider)
      .getHistoryByClassroom(classroomId);
});
