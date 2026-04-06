import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/utils/auth_role_utils.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/children/screens/children_list_screen.dart';
import '../../features/children/screens/child_detail_screen.dart';
import '../../features/children/screens/child_add_screen.dart';
import '../../features/children/screens/child_edit_screen.dart';
import '../../features/servants/screens/servants_list_screen.dart';
import '../../features/servants/screens/servant_detail_screen.dart';
import '../../features/servants/screens/servant_add_screen.dart';
import '../../features/servants/screens/servant_edit_screen.dart';
import '../../features/attendance/screens/attendance_take_screen.dart';
import '../../features/attendance/screens/attendance_view_screen.dart';
import '../../features/super_admin/screens/super_admin_home_screen.dart';
import '../../features/classrooms/screens/classrooms_home_screen.dart';
import '../../core/storage/token_storage.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final hasToken = await TokenStorage.hasToken();
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!hasToken && !onAuthPage) return '/login';
      if (hasToken && onAuthPage) {
        final token = await TokenStorage.getToken();
        final role = token != null ? AuthRoleUtils.extractPrimaryRole(token) : null;
        return AuthRoleUtils.routeForRole(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: '/super-admin-home',
        builder: (_, __) => const SuperAdminHomeScreen(),
      ),
      GoRoute(
        path: '/classrooms-home',
        builder: (_, __) => const ClassroomsHomeScreen(),
      ),

      // Children
      GoRoute(path: '/children', builder: (_, __) => const ChildrenListScreen()),
      GoRoute(
        path: '/children/add',
        builder: (_, __) => const ChildAddScreen(),
      ),
      GoRoute(
        path: '/children/:id',
        builder: (_, state) => ChildDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/children/:id/edit',
        builder: (_, state) => ChildEditScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Servants
      GoRoute(path: '/servants', builder: (_, __) => const ServantsListScreen()),
      GoRoute(path: '/servants/add', builder: (_, __) => const ServantAddScreen()),
      GoRoute(
        path: '/servants/:id',
        builder: (_, state) => ServantDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/servants/:id/edit',
        builder: (_, state) => ServantEditScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Attendance
      GoRoute(
        path: '/attendance/take',
        builder: (_, state) {
          final classroomId = state.uri.queryParameters['classroomId'] != null
              ? int.tryParse(state.uri.queryParameters['classroomId']!)
              : null;
          return AttendanceTakeScreen(classroomId: classroomId);
        },
      ),
      GoRoute(
        path: '/attendance/:id',
        builder: (_, state) => AttendanceViewScreen(
          sessionId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
