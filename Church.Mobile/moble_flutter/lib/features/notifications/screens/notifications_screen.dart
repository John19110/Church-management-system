import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/app_notification.dart';
import '../providers/notifications_providers.dart';
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../../shared/widgets/common_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final inboxAsync = ref.watch(notificationInboxProvider);

    return PopScope(
      canPop: currentLocation == homeRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.notifications)),
        body: SafeArea(
          child: inboxAsync.when(
            loading: () => const LoadingWidget(useSkeleton: true),
            error: (e, _) => AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () => ref.invalidate(notificationInboxProvider),
            ),
            data: (items) {
              if (items.isEmpty) {
                return EmptyWidget(
                  title: l10n.notifications,
                  message: l10n.noNotificationsYet,
                  icon: Icons.notifications_none_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(notificationInboxProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationTile(
                      notification: item,
                      onTap: () => _openNotification(context, ref, item),
                    );
                  },
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: AppSectionBottomNavigationBar(
          currentIndex: 1,
          homeRoute: homeRoute,
        ),
      ),
    );
  }

  Future<void> _openNotification(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    await ref
        .read(notificationInboxProvider.notifier)
        .markAsRead(notification.id);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(notification.title ?? AppLocalizations.of(ctx).notifications),
        content: SingleChildScrollView(
          child: Text(
            notification.body ?? '',
            style: Theme.of(ctx).textTheme.bodyLarge,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).cancel),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.yMMMd().add_jm().format(notification.receivedAt.toLocal());

    return ListTile(
      leading: Icon(
        notification.isRead
            ? Icons.notifications_none_outlined
            : Icons.notifications_active_outlined,
        color: notification.isRead
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
      title: Text(
        notification.title ?? '—',
        style: notification.isRead
            ? theme.textTheme.titleMedium
            : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null && notification.body!.isNotEmpty)
            Text(
              notification.body!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          Text(time, style: theme.textTheme.bodySmall),
        ],
      ),
      isThreeLine: notification.body != null && notification.body!.isNotEmpty,
      onTap: onTap,
    );
  }
}
