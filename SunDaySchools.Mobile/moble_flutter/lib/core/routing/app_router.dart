import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/registration_type_screen.dart';
import '../../features/auth/screens/new_church_role_screen.dart';
// Phone verification disabled
// import '../../features/auth/screens/otp_verification_screen.dart';
// import '../../features/auth/screens/forgot_password_screen.dart';
// import '../../features/auth/screens/reset_password_screen.dart';
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
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../features/super_admin/screens/super_admin_home_screen.dart';
import '../../features/super_admin/screens/super_admin_pending_admins_screen.dart';
import '../../features/super_admin/screens/super_admin_pending_users_screen.dart';
import '../../features/meeting/models/meeting_models.dart';
import '../../features/meeting/screens/meeting_detail_screen.dart';
import '../../features/church/screens/church_detail_screen.dart';
import '../../features/classroom/models/classroom_models.dart';
import '../../features/classroom/screens/classroom_detail_screen.dart';
import '../../features/classroom/screens/classroom_add_screen.dart';
import '../../features/classroom/screens/classrooms_home_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_pending_servants_screen.dart';
import '../../features/servant/screens/servant_home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/custom_field/screens/custom_field_definitions_screen.dart';
import '../../features/custom_field/screens/custom_field_definition_form_screen.dart';
import '../../features/unified_form/screens/unified_entity_edit_screen.dart';
import '../../features/unified_form/models/unified_form_models.dart';
import '../../features/custom_field/models/custom_field_models.dart';
import '../../core/storage/token_storage.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const registerExistingChurch = '/register/existing-church';
  static const registerNewChurch = '/register/new-church';
  static const registerNewChurchMeetingAdmin =
      '/register/new-church/meeting-admin';
  static const registerNewChurchSuperAdmin =
      '/register/new-church/super-admin';
  // Phone verification disabled
  // static const verifyPhone = '/verify-phone';
  // static const forgotPassword = '/forgot-password';
  // static const resetPassword = '/reset-password';
  static const dashboard = '/dashboard';
  static const superAdminHome = '/super-admin-home';
  static const adminHome = '/admin-home';
  static const servantHome = '/servant-home';
  static const classroomsHome = '/classrooms-home';
  static const profile = '/profile';
  static const profileEdit = '/profile/edit';
  static const pendingAdmins = '/super-admin/pending-admins';
  static const pendingUsers = '/super-admin/pending-users';
  static const pendingServants = '/admin/pending-servants';
  static const meetingDetail = '/meeting-detail';
  static const churchSettings = '/church';
  static const classroomDetail = '/classroom-detail';
  static const member = '/member';
  static const notifications = '/notifications';
  static const servants = '/servants';
  static const attendanceTake = '/attendance/take';
  static const attendanceHistory = '/attendance/history';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,

    redirect: (context, state) async {
      final hasToken = TokenStorage.isCacheWarm
          ? TokenStorage.cachedToken?.isNotEmpty == true
          : await TokenStorage.hasToken();

      final loc = state.matchedLocation;
      final onAuthPage = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc.startsWith(AppRoutes.register);
          // Phone verification disabled
          // loc.startsWith(AppRoutes.verifyPhone) ||
          // loc == AppRoutes.forgotPassword ||
          // loc.startsWith(AppRoutes.resetPassword);

      if (!hasToken && !onAuthPage) {
        return AppRoutes.login;
      }

      if (hasToken && onAuthPage) {
        final token = TokenStorage.cachedToken ?? await TokenStorage.getToken();
        final role = token != null
            ? AuthRoleUtils.extractPrimaryRole(token)
            : null;

        return AuthRoleUtils.routeForRole(role);
      }

      return null;
    },

    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegistrationTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerExistingChurch,
        builder: (_, __) =>
            const RegisterScreen(mode: RegisterFormMode.existingChurchMember),
      ),
      GoRoute(
        path: AppRoutes.registerNewChurch,
        builder: (_, __) => const NewChurchRoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.registerNewChurchMeetingAdmin,
        builder: (_, __) =>
            const RegisterScreen(mode: RegisterFormMode.newChurchMeetingAdmin),
      ),
      GoRoute(
        path: AppRoutes.registerNewChurchSuperAdmin,
        builder: (_, __) =>
            const RegisterScreen(mode: RegisterFormMode.newChurchSuperAdmin),
      ),
      // Phone verification disabled
      // GoRoute(
      //   path: AppRoutes.verifyPhone,
      //   builder: (_, state) {
      //     final phone = state.uri.queryParameters['phone'] ?? '';
      //     return OtpVerificationScreen(phoneNumber: phone);
      //   },
      // ),
      // GoRoute(
      //   path: AppRoutes.forgotPassword,
      //   builder: (_, __) => const ForgotPasswordScreen(),
      // ),
      // GoRoute(
      //   path: AppRoutes.resetPassword,
      //   builder: (_, state) {
      //     final phone = state.uri.queryParameters['phone'] ?? '';
      //     return ResetPasswordScreen(phoneNumber: phone);
      //   },
      // ),
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
        builder: (_, state) {
          int? meetingId;
          String? meetingName;

          final extra = state.extra;
          if (extra is Map) {
            final rawMeetingId = extra['meetingId'];
            final rawMeetingName = extra['meetingName'];
            if (rawMeetingId is int) meetingId = rawMeetingId;
            if (rawMeetingName is String) meetingName = rawMeetingName;
          }

          meetingId ??= state.uri.queryParameters['meetingId'] != null
              ? int.tryParse(state.uri.queryParameters['meetingId']!)
              : null;
          meetingName ??= state.uri.queryParameters['meetingName'];

          return ClassroomsHomeScreen(
            meetingId: meetingId,
            meetingName: meetingName,
          );
        },
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
        path: AppRoutes.pendingUsers,
        builder: (_, __) => const SuperAdminPendingUsersScreen(),
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
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.meetingDetails,
            );
          }
          return MeetingDetailScreen(meeting: meeting);
        },
      ),

      GoRoute(
        path: '/meetings/:id/edit',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.editMeeting,
            );
          }
          return Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return UnifiedEntityEditScreen(
                entityName: UnifiedEntityNames.meeting,
                entityId: id,
                title: l10n.editMeeting,
              );
            },
          );
        },
      ),

      GoRoute(
        path: AppRoutes.churchSettings,
        redirect: (_, __) async {
          final token = TokenStorage.cachedToken ?? await TokenStorage.getToken();
          if (token == null) return AppRoutes.login;
          final churchId = AuthRoleUtils.extractChurchId(token);
          if (churchId == null || churchId <= 0) return AppRoutes.dashboard;
          return '/church/$churchId';
        },
      ),

      GoRoute(
        path: '/church/:id',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.entityChurch,
            );
          }
          return ChurchDetailScreen(churchId: id);
        },
      ),

      GoRoute(
        path: '/church/:id/edit',
        builder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null || id <= 0) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.editChurch,
            );
          }
          return Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return UnifiedEntityEditScreen(
                entityName: UnifiedEntityNames.church,
                entityId: id,
                title: l10n.editChurch,
              );
            },
          );
        },
      ),

      GoRoute(
        path: AppRoutes.classroomDetail,
        builder: (_, state) {
          final classroom = state.extra;
          if (classroom is! ClassroomReadDto) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.classroomDetails,
            );
          }
          return ClassroomDetailScreen(classroom: classroom);
        },
      ),

      GoRoute(
        path: '/classrooms/add',
        builder: (_, state) {
          int? meetingId;
          final extra = state.extra;
          if (extra is int && extra > 0) {
            meetingId = extra;
          } else {
            final raw = state.uri.queryParameters['meetingId'];
            if (raw != null) meetingId = int.tryParse(raw);
          }
          return ClassroomAddScreen(meetingId: meetingId);
        },
      ),

      // Members
      GoRoute(
        path: AppRoutes.member,
        builder: (_, __) => const MembersListScreen(),
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
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
        path: '/custom-fields/:entityName',
        builder: (_, state) => CustomFieldDefinitionsScreen(
          entityName: state.pathParameters['entityName']!,
        ),
      ),
      GoRoute(
        path: '/custom-fields/:entityName/new',
        builder: (_, state) => CustomFieldDefinitionFormScreen(
          entityName: state.pathParameters['entityName']!,
        ),
      ),
      GoRoute(
        path: '/custom-fields/:entityName/edit/:id',
        builder: (_, state) {
          final existing = state.extra;
          return CustomFieldDefinitionFormScreen(
            entityName: state.pathParameters['entityName']!,
            existing: existing is CustomFieldDefinitionReadDto ? existing : null,
          );
        },
      ),
      GoRoute(
        path: '/custom-fields/values/:entityName/:entityId',
        builder: (_, state) {
          final entityId = int.tryParse(state.pathParameters['entityId'] ?? '');
          if (entityId == null || entityId <= 0) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.customFieldValues,
            );
          }
          return UnifiedEntityEditScreen(
            entityName: state.pathParameters['entityName']!,
            entityId: entityId,
          );
        },
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
        path: '${AppRoutes.attendanceHistory}/:classroomId',
        builder: (_, state) {
          final classroomId = int.tryParse(state.pathParameters['classroomId'] ?? '');
          if (classroomId == null) {
            return _MissingRouteDataScreen(
              titleBuilder: (l10n) => l10n.attendanceHistory,
            );
          }
          final classroomName = state.uri.queryParameters['classroomName'];
          return AttendanceHistoryScreen(
            classroomId: classroomId,
            classroomName: classroomName,
          );
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
      body: Center(
        child: Text('${AppLocalizations.of(context).pageNotFound} ${state.error}'),
      ),
    ),
  );
});

typedef _RouteTitleBuilder = String Function(AppLocalizations l10n);

class _MissingRouteDataScreen extends StatelessWidget {
  final _RouteTitleBuilder titleBuilder;

  const _MissingRouteDataScreen({required this.titleBuilder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(titleBuilder(l10n))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocalizations.of(context).missingRequiredData),
        ),
      ),
    );
  }
}