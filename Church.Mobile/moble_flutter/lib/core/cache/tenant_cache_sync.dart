import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cache_providers.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Keeps local cache tenant-isolated on tenant switches:
/// when the active ChurchId changes, deletes only the previous tenant's cached entries.
final tenantCacheSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<int?>>(currentChurchIdProvider, (previous, next) async {
    final prevId = previous?.valueOrNull;
    final nextId = next.valueOrNull;
    if (prevId != null && prevId > 0 && nextId != null && nextId > 0) {
      if (prevId != nextId) {
        await ref.read(localCacheServiceProvider).clearTenant(prevId);
      }
    }
  });
});

