import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/super_admin_models.dart';
import '../repositories/super_admin_repository.dart';

final superAdminRepositoryProvider = Provider((ref) {
  return SuperAdminRepository(ref.watch(dioProvider));
});

final pendingAdminsProvider =
    FutureProvider<List<PendingUserDto>>((ref) async {
  return ref.watch(superAdminRepositoryProvider).getPendingAdmins();
});
