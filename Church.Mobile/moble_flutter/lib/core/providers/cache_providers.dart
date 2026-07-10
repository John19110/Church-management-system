import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_manager.dart';
import '../cache/local_cache_service.dart';

final localCacheServiceProvider = Provider<LocalCacheService>((ref) {
  return LocalCacheService();
});

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager(ref.watch(localCacheServiceProvider));
});

