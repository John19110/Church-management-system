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
import '../../features/meetings/models/meeting_models.dart';
import '../../features/meetings/screens/meeting_detail_screen.dart';
import '../../features/classrooms/models/classroom_models.dart';
import '../../features/classrooms/screens/classroom_detail_screen.dart';
import '../../features/classrooms/screens/classrooms_home_screen.dart';
import '../../core/storage/token_storage.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const superAdminHome = '/super-admin-home';
  static const classroomsHome = '/classrooms-home';
  static const meetingDetail = '/meeting-detail';
  static const classroomDetail = '/classroom-detail';
  static const children = '/children';
  static const servants = '/servants';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) async {
      final hasToken = await TokenStorage.hasToken();
      final onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (!hasToken && !onAuthPage) return AppRoutes.login;
      if (hasToken && onAuthPage) {
        final token = await TokenStorage.getToken();
        final role = token != null ? AuthRoleUtils.extractPrimaryRole(token) : null;
        return AuthRoleUtils.routeForRole(role);
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(
        path: AppRoutes.superAdminHome,
        builder: (_, __) => const SuperAdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.classroomsHome,
        builder: (_, __) => const ClassroomsHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.meetingDetail,
        builder: (_, state) {
          final meeting = state.extra;
          if (meeting is! MeetingReadDto) {
            return const _MissingRouteDataScreen(title: 'Meeting details');
          }
          return MeetingDetailScreen(meeting: meeting);
        },
      ),
      GoRoute(
        path: AppRoutes.classroomDetail,
        builder: (_, state) {
          final classroom = state.extra;
          if (classroom is! ClassroomReadDto) {
            return const _MissingRouteDataScreen(title: 'Classroom details');
          }
          return ClassroomDetailScreen(classroom: classroom);
        },
      ),

      // Children
      GoRoute(path: AppRoutes.children, builder: (_, __) => const ChildrenListScreen()),
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
      GoRoute(path: AppRoutes.servants, builder: (_, __) => const ServantsListScreen()),
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

class _MissingRouteDataScreen extends StatelessWidget {
  final String title;

  const _MissingRouteDataScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Missing required data for this screen.'),
        ),
      ),
    );
  }
}
