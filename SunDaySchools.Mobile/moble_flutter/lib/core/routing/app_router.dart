import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/utils/auth_role_utils.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/member/screens/members_list_screen.dart';
import '../../features/member/screens/member_detail_screen.dart';
import '../../features/member/screens/member_add_screen.dart';
import '../../features/member/screens/member_edit_screen.dart';
import '../../features/servant/screens/servants_list_screen.dart';
import '../../features/servant/screens/servant_detail_screen.dart';
import '../../features/servant/screens/servant_edit_screen.dart';
import '../../features/servant/screens/profile_screen.dart';
import '../../features/servant/screens/edit_profile_screen.dart';
import '../../features/attendance/screens/attendance_take_screen.dart';
import '../../features/attendance/screens/attendance_view_screen.dart';
import '../../features/super_admin/screens/super_admin_home_screen.dart';
import '../../features/super_admin/screens/super_admin_pending_admins_screen.dart';
import '../../features/meeting/models/meeting_models.dart';
import '../../features/meeting/screens/meeting_detail_screen.dart';
import '../../features/classroom/models/classroom_models.dart';
import '../../features/classroom/screens/classroom_detail_screen.dart';
import '../../features/classroom/screens/classrooms_home_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_pending_servants_screen.dart';
import '../../features/servant/screens/servant_home_screen.dart';
import '../../core/storage/token_storage.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/dashboard';
  static const superAdminHome = '/super-admin-home';
  static const adminHome = '/admin-home';
  static const servantHome = '/servant-home';
  static const classroomsHome = '/classrooms-home';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const pendingAdmins = '/super-admin/pending-admins';
  static const pendingServants = '/admin/pending-servants';
  static const meetingDetail = '/meeting-detail';
  static const classroomDetail = '/classroom-detail';
  static const member = '/member';
  static const servants = '/servants';
  static const attendanceTake = '/attendance/take';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,

    redirect: (context, state) async {
      final hasToken = await TokenStorage.hasToken();

      final onAuthPage = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      if (!hasToken && !onAuthPage) {
        return AppRoutes.login;
      }

      if (hasToken && onAuthPage) {
        final token = await TokenStorage.getToken();
        final role = token != null
            ? AuthRoleUtils.extractPrimaryRole(token)
            : null;

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
        path: AppRoutes.adminHome,
        builder: (_, __) => const AdminHomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.servantHome,
        builder: (_, __) => const ServantHomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.classroomsHome,
        builder: (_, __) => const ClassroomsHomeScreen(),
      ),

      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.profileEdit,
        builder: (_, __) => const EditProfileScreen(),
      ),

      GoRoute(
        path: AppRoutes.pendingAdmins,
        builder: (_, __) => const SuperAdminPendingAdminsScreen(),
      ),

      GoRoute(
        path: AppRoutes.pendingServants,
        builder: (_, __) => const AdminPendingServantsScreen(),
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

      // Members
      GoRoute(
        path: AppRoutes.member,
        builder: (_, __) => const MembersListScreen(),
      ),

      GoRoute(
        path: '/members/add',
        builder: (_, state) {
          final classroomId =
          state.extra is int ? state.extra as int : null;
          return MemberAddScreen(classroomId: classroomId);
        },
      ),

      GoRoute(
        path: '/member/:id',
        builder: (_, state) => MemberDetailScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),

      GoRoute(
        path: '/member/:id/edit',
        builder: (_, state) => MemberEditScreen(
          id: int.parse(state.pathParameters['id']!),
        ),
      ),

      // Servants
      GoRoute(
        path: AppRoutes.servants,
        builder: (_, __) => const ServantsListScreen(),
      ),

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
        path: AppRoutes.attendanceTake,
        builder: (_, state) {
          final classroomId =
          state.uri.queryParameters['classroomId'] != null
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