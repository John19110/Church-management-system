import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
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
