import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_list_row.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../../shared/widgets/app_section_navigation.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/servant_models.dart';
import '../providers/pending_requests_provider.dart';
import '../providers/servants_providers.dart';
import '../widgets/pending_requests_panel.dart';

class ServantsListScreen extends ConsumerStatefulWidget {
  final int? meetingId;
  final String? meetingName;
  final bool initialPending;

  const ServantsListScreen({
    super.key,
    this.meetingId,
    this.meetingName,
    this.initialPending = false,
  });

  @override
  ConsumerState<ServantsListScreen> createState() => _ServantsListScreenState();
}

class _ServantsListScreenState extends ConsumerState<ServantsListScreen> {
  bool _showPending = false;
  String _query = '';

  bool get _isMeetingScoped => widget.meetingId != null;

  @override
  void initState() {
    super.initState();
    _showPending = widget.initialPending;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final servantsAsync = _isMeetingScoped
        ? ref.watch(servantsByMeetingProvider(widget.meetingId!))
        : ref.watch(servantsListProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final canReview = !_isMeetingScoped &&
        (role == 'superadmin' || role == 'admin');
    final pendingCount = canReview ? ref.watch(pendingRequestCountProvider) : 0;

    void invalidateServants() {
      if (_isMeetingScoped) {
        ref.invalidate(servantsByMeetingProvider(widget.meetingId!));
      } else {
        ref.invalidate(servantsListProvider);
      }
    }

    String buildTitle() {
      final base = l10n.servants;
      if (_isMeetingScoped && widget.meetingName != null) {
        return '$base — ${widget.meetingName}';
      }
      return base;
    }

    return PopScope(
      canPop: _isMeetingScoped,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.go(homeRoute);
      },
      child: AppAdaptiveScaffold(
        destination: _isMeetingScoped ? null : AppNavDestination.servants,
        homeRoute: homeRoute,
        role: role,
        constrainBody: false,
        appBar: AppBar(title: Text(buildTitle())),
        body: Column(
          children: [
            if (canReview)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.activeServants),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(
                        pendingCount > 0
                            ? '${l10n.pendingRequests} $pendingCount'
                            : l10n.pendingRequests,
                      ),
                    ),
                  ],
                  selected: {_showPending},
                  onSelectionChanged: (next) {
                    setState(() => _showPending = next.contains(true));
                  },
                ),
              ),
            Expanded(
              child: canReview && _showPending
                  ? const PendingRequestsPanel()
                  : _ActiveServantsList(
                      servantsAsync: servantsAsync,
                      query: _query,
                      onQueryChanged: (value) => setState(() => _query = value),
                      onRefresh: invalidateServants,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveServantsList extends StatelessWidget {
  final AsyncValue<List<ServantReadDto>> servantsAsync;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onRefresh;

  const _ActiveServantsList({
    required this.servantsAsync,
    required this.query,
    required this.onQueryChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return servantsAsync.when(
      loading: () => const cw.LoadingWidget(useSkeleton: true),
      error: (e, _) => cw.AppErrorWidget(
        message: userFriendlyMessage(e, l10n),
        onRetry: onRefresh,
      ),
      data: (servants) {
        final needle = query.trim().toLowerCase();
        final filtered = needle.isEmpty
            ? servants
            : servants.where((servant) {
                final name = (servant.name ?? '').toLowerCase();
                final phone = (servant.phoneNumber ?? '').toLowerCase();
                return name.contains(needle) || phone.contains(needle);
              }).toList();

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            children: [
              TextField(
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.searchServants,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: cw.EmptyWidget(
                    title: l10n.noServantsYetTitle,
                    message: l10n.noServantsYetBody,
                    icon: Icons.people_outline,
                  ),
                )
              else
                for (final servant in filtered) ...[
                  AppListRow(
                    key: ValueKey('servant-${servant.id}'),
                    leading: AppNetworkAvatar(
                      imageUrl: servant.displayImageUrl,
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      placeholder: Text(
                        (servant.name?.isNotEmpty == true)
                            ? servant.name![0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: servant.name ?? l10n.unknownName,
                    subtitle: [
                      if ((servant.phoneNumber ?? '').isNotEmpty)
                        servant.phoneNumber,
                      l10n.servantActive,
                    ].whereType<String>().join(' · '),
                    onTap: () async {
                      if (servant.id <= 0) {
                        if (context.mounted) {
                          cw.showErrorSnackbar(
                            context,
                            l10n.servantIdMissingFromApi,
                          );
                        }
                        return;
                      }
                      await context.push('/servants/${servant.id}');
                      onRefresh();
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
            ],
          ),
        );
      },
    );
  }
}
