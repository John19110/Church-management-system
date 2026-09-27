import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../providers/pending_requests_provider.dart';
import 'pending_request_card.dart';

class PendingRequestsPanel extends ConsumerWidget {
  const PendingRequestsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(pendingRequestsProvider);

    return pendingAsync.when(
      loading: () => const cw.LoadingWidget(useSkeleton: true),
      error: (e, _) => cw.AppErrorWidget(
        message: userFriendlyMessage(e, l10n),
        onRetry: () => invalidatePendingRequests(ref),
      ),
      data: (requests) {
        if (requests.isEmpty) {
          return cw.EmptyWidget(
            title: l10n.noPendingRequests,
            message: l10n.noPendingRequestsBody,
            icon: Icons.pending_actions_outlined,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => invalidatePendingRequests(ref),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: requests.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    l10n.pendingRequestsCount(requests.length),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final request = requests[index - 1];
              return PendingRequestCard(
                key: ValueKey('pending-${request.source.name}-${request.id}'),
                request: request,
              );
            },
          ),
        );
      },
    );
  }
}
