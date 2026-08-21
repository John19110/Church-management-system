import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import '../../classroom/screens/classrooms_home_screen.dart';
import '../../meeting/models/meeting_models.dart';
import '../../meeting/providers/meeting_providers.dart';
import 'admin_pending_users_screen.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final meetingsAsync = ref.watch(visibleMeetingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.admin),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.class_),
                text: meetingsAsync.maybeWhen(
                  data: (meetings) {
                    final meeting = _primaryMeeting(meetings);
                    if (meeting != null && !meeting.hasClassrooms) {
                      return l10n.meetingHome;
                    }
                    return l10n.classrooms;
                  },
                  orElse: () => l10n.classrooms,
                ),
              ),
              Tab(
                icon: const Icon(Icons.pending_actions),
                text: l10n.pendingUsers,
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logoutSession(ref, context),
            ),
          ],
        ),
        body: roleAsync.when(
          data: (role) {
            if (role == 'admin') {
              return TabBarView(
                children: [
                  meetingsAsync.when(
                    loading: () =>
                        const cw.LoadingWidget(useSkeleton: true),
                    error: (e, _) => cw.AppErrorWidget(
                      message: userFriendlyMessage(e, l10n),
                      onRetry: () =>
                          ref.invalidate(visibleMeetingsProvider),
                    ),
                    data: (meetings) {
                      final meeting = _primaryMeeting(meetings);
                      if (meeting != null &&
                          meeting.id != null &&
                          !meeting.hasClassrooms) {
                        return _MeetingWithoutClassroomsHome(
                          meeting: meeting,
                        );
                      }
                      return const ClassroomsHomeScreen(showAppBar: false);
                    },
                  ),
                  const AdminPendingUsersScreen(),
                ],
              );
            }
            if (role == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.noRoleFoundPleaseRelogin,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.adminOnlyScreen,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${l10n.couldNotVerifyRole} $e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  MeetingReadDto? _primaryMeeting(List<MeetingReadDto> meetings) {
    if (meetings.isEmpty) return null;
    return meetings.first;
  }
}

class _MeetingWithoutClassroomsHome extends StatelessWidget {
  final MeetingReadDto meeting;

  const _MeetingWithoutClassroomsHome({required this.meeting});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final meetingId = meeting.id!;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        Text(
          meeting.name?.trim().isNotEmpty == true
              ? meeting.name!
              : l10n.meetingHome,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.divideMeetingIntoClassroomsHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: () => context.push(
            '/meetings/$meetingId/members',
            extra: meeting.name,
          ),
          icon: const Icon(Icons.group),
          label: Text(l10n.addUpdateRemoveMembers),
        ),
        const SizedBox(height: AppSpacing.sm),
        ElevatedButton.icon(
          onPressed: () => context.push(
            '${AppRoutes.attendanceTake}?meetingId=$meetingId',
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: Text(l10n.takeAttendance),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(
            '${AppRoutes.attendanceHistory}/meeting/$meetingId',
            extra: meeting.name,
          ),
          icon: const Icon(Icons.history),
          label: Text(l10n.attendanceHistory),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => context.push(
            '/meetings/$meetingId/servants',
            extra: meeting.name,
          ),
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(l10n.manageServants),
        ),
      ],
    );
  }
}
