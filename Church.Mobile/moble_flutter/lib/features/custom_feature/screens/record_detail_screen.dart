import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class RecordDetailScreen extends ConsumerWidget {
  final int entityId;
  final int recordId;

  const RecordDetailScreen({
    super.key,
    required this.entityId,
    required this.recordId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final entityAsync = ref.watch(customEntityProvider(entityId));
    final recordAsync = ref.watch(customRecordProvider((entityId, recordId)));

    return entityAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: const LoadingWidget(useSkeleton: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: AppErrorWidget(message: userFriendlyMessage(e, l10n)),
      ),
      data: (entity) {
        return recordAsync.when(
          loading: () => Scaffold(
            appBar: AppBar(title: Text(entityDisplayName(entity, l10n))),
            body: const LoadingWidget(useSkeleton: true),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: Text(entityDisplayName(entity, l10n))),
            body: AppErrorWidget(
              message: userFriendlyMessage(e, l10n),
              onRetry: () =>
                  ref.invalidate(customRecordProvider((entityId, recordId))),
            ),
          ),
          data: (record) {
            final permission = entity.permissionForRole(role);
            final fields = entity.fields.where((f) => f.showOnDetails).toList()
              ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
            return Scaffold(
              appBar: AppBar(
                title: Text(recordTitle(record, entity, l10n)),
                actions: [
                  if (permission?.canUpdate == true)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push(
                        '${AppRoutes.customEntities}/$entityId/records/$recordId/edit',
                      ),
                    ),
                  if (permission?.canDelete == true)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await showConfirmDialog(
                          context,
                          title: l10n.deleteRecord,
                          content: l10n.deleteRecordForever,
                        );
                        if (!ok) return;
                        try {
                          await ref
                              .read(customFeatureRepositoryProvider)
                              .deleteRecord(
                                entityId: entityId,
                                recordId: recordId,
                              );
                          bumpCustomFeatures(ref);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) {
                            showErrorSnackbar(
                              context,
                              userFriendlyMessage(e, l10n),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
              body: fields.isEmpty
                  ? EmptyWidget(message: l10n.noFieldsConfigured)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final field in fields)
                          ListTile(
                            title: Text(fieldDisplayName(field, l10n)),
                            subtitle: Text(
                              formatRecordValue(record, field, l10n).isEmpty
                                  ? '—'
                                  : formatRecordValue(record, field, l10n),
                            ),
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
