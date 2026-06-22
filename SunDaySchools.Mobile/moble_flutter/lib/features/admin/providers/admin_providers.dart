import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../super_admin/models/super_admin_models.dart';
import '../models/admin_models.dart';
import '../repositories/admin_repository.dart';

final adminRepositoryProvider = Provider((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

final pendingServantsProvider =
    FutureProvider<List<PendingUserDto>>((ref) async {
  return ref.watch(adminRepositoryProvider).getPendingServants();
});

final adminPendingChurchUsersProvider =
    FutureProvider<List<PendingChurchUserDto>>((ref) async {
  ref.watch(authSessionEpochProvider);
  return ref.watch(adminRepositoryProvider).getPendingUsers();
});
