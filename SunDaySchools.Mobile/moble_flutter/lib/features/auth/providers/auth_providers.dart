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

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final token = await TokenStorage.getToken();
  if (token == null || token.isEmpty) return null;
  return AuthRoleUtils.extractPrimaryRole(token);
});
