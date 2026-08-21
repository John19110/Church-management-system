import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/attendance_models.dart';
import '../models/attendance_criterion_models.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/attendance_criterion_repository.dart';

final attendanceRepositoryProvider = Provider((ref) {
  return AttendanceRepository(ref.watch(dioProvider));
});

final attendanceCriterionRepositoryProvider = Provider((ref) {
  return AttendanceCriterionRepository(ref.watch(dioProvider));
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

final attendanceHistoryByMeetingProvider =
    FutureProvider.family<List<AttendanceSessionSummaryDto>, int>(
        (ref, meetingId) async {
  return ref
      .watch(attendanceRepositoryProvider)
      .getHistoryByMeeting(meetingId);
});

final attendanceCriteriaByMeetingProvider =
    FutureProvider.family<List<AttendanceCriterionDto>, int>(
        (ref, meetingId) async {
  return ref
      .watch(attendanceCriterionRepositoryProvider)
      .getByMeeting(meetingId);
});

final attendanceCriteriaManageProvider =
    FutureProvider.family<List<AttendanceCriterionDto>, int>(
        (ref, meetingId) async {
  return ref.watch(attendanceCriterionRepositoryProvider).getByMeeting(
        meetingId,
        includeInactive: true,
      );
});
