import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../providers/auth_providers.dart';

/// Server logout (optional), clear stored JWT, reset auth-related providers, go to login.
Future<void> logoutSession(WidgetRef ref, BuildContext context) async {
  await ref.read(authRepositoryProvider).logout();
  ref.invalidate(currentUserRoleProvider);
  ref.read(authStateProvider.notifier).state = false;
  if (!context.mounted) return;
  context.go(AppRoutes.login);
}
