import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../repositories/auth_repository.dart';
import '../utils/auth_role_utils.dart';

final dioProvider = Provider((ref) => createDio());

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(ref.watch(dioProvider));
});

/// Tracks the current auth state: null = not known yet, true = logged in, false = logged out
final authStateProvider = StateProvider<bool>((ref) => false);

/// Increment on login, logout, or register so role/data providers refetch for the new session.
/// Avoids stale [FutureProvider] cache when switching accounts on the same device.
final authSessionEpochProvider = StateProvider<int>((ref) => 0);

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  ref.watch(authSessionEpochProvider);
  final token = await TokenStorage.getToken();
  if (token == null || token.isEmpty) return null;
  return AuthRoleUtils.extractPrimaryRole(token);
});

extension ResolvedRoleAsyncX on AsyncValue<String?> {
  /// Use instead of [valueOrNull] when switching users: during reload, [valueOrNull]
  /// can still expose the previous account's role briefly.
  String? get resolvedRoleOrNull => when(
        data: (r) => r,
        loading: () => null,
        error: (_, __) => null,
      );
}
