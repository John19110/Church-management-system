import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../admin/providers/admin_providers.dart';
import '../../auth/providers/auth_providers.dart';
import '../../super_admin/providers/super_admin_providers.dart';
import '../models/pending_request.dart';

final pendingRequestsProvider = FutureProvider<List<PendingRequest>>((ref) async {
  ref.watch(authSessionEpochProvider);
  final role = await ref.watch(currentUserRoleProvider.future);
  if (role == 'superadmin') {
    final registrations = await ref.watch(pendingChurchUsersProvider.future);
    final admins = await ref.watch(pendingAdminsProvider.future);
    return mergePendingRequests(
      registrations: registrations,
      legacyAdmins: admins,
    );
  }
  if (role == 'admin') {
    final registrations =
        await ref.watch(adminPendingChurchUsersProvider.future);
    final servants = await ref.watch(pendingServantsProvider.future);
    return mergePendingRequests(
      registrations: registrations,
      legacyServants: servants,
    );
  }
  return const [];
});

final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(pendingRequestsProvider).maybeWhen(
        data: (requests) => requests.length,
        orElse: () => 0,
      );
});

void invalidatePendingRequests(WidgetRef ref) {
  ref.invalidate(pendingRequestsProvider);
  ref.invalidate(pendingChurchUsersProvider);
  ref.invalidate(pendingAdminsProvider);
  ref.invalidate(adminPendingChurchUsersProvider);
  ref.invalidate(pendingServantsProvider);
}
