import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/member_models.dart';
import '../repositories/members_repository.dart';

final membersRepositoryProvider = Provider((ref) {
  return MembersRepository(ref.watch(dioProvider));
});

final membersListProvider = FutureProvider<List<MemberReadDto>>((ref) async {
  return ref.watch(membersRepositoryProvider).getAll();
});

final memberDetailProvider = FutureProvider.family<MemberReadDto, int>((ref, id) async {
  return ref.watch(membersRepositoryProvider).getById(id);
});

/// Members assigned to a classroom (includes photo URLs for list UI).
final membersByClassroomProvider =
    FutureProvider.family<List<MemberReadDto>, int>((ref, classroomId) async {
  return ref.watch(membersRepositoryProvider).getByClassroom(classroomId);
});
