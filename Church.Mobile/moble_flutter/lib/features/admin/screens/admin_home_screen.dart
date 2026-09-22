import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_session.dart';
import '../../meeting/models/meeting_models.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../meeting/screens/meeting_detail_screen.dart';

/// Meeting Admin home: same Meeting preview as SuperAdmin (`MeetingDetailScreen`),
/// including Settings FAB, for the Meeting they manage.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final roleAsync = ref.watch(currentUserRoleProvider);
    final meetingsAsync = ref.watch(visibleMeetingsProvider);

    return roleAsync.when(
      data: (role) {
        if (role != 'admin') {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.admin)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  role == null
                      ? l10n.noRoleFoundPleaseRelogin
                      : l10n.adminOnlyScreen,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return meetingsAsync.when(
          loading: () => const Scaffold(
            body: cw.LoadingWidget(useSkeleton: true),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(
              title: Text(l10n.admin),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => logoutSession(ref, context),
                ),
              ],
            ),
            body: cw.AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(visibleMeetingsProvider),
            ),
            bottomNavigationBar: const AppSectionBottomNavigationBar(
              currentIndex: 0,
              homeRoute: AppRoutes.adminHome,
            ),
          ),
          data: (meetings) {
            final meeting = _primaryManagedMeeting(meetings);
            if (meeting == null) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(l10n.admin),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => logoutSession(ref, context),
                    ),
                  ],
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noVisibleMeetingsFound,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                bottomNavigationBar: const AppSectionBottomNavigationBar(
                  currentIndex: 0,
                  homeRoute: AppRoutes.adminHome,
                ),
              );
            }

            return MeetingDetailScreen(
              meeting: meeting,
              showSectionBottomNav: true,
            );
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.admin)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${l10n.couldNotVerifyRole} $e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// API already scopes Admin to their Meeting; take that single managed Meeting.
  MeetingReadDto? _primaryManagedMeeting(List<MeetingReadDto> meetings) {
    if (meetings.isEmpty) return null;
    return meetings.first;
  }
}
