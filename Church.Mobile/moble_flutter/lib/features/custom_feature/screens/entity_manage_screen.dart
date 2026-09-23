import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class EntityManageScreen extends ConsumerWidget {
  final int entityId;

  const EntityManageScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(customEntityProvider(entityId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.customEntities)),
        body: const LoadingWidget(useSkeleton: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customEntities)),
        body: AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customEntityProvider(entityId)),
        ),
      ),
      data: (entity) {
        return Scaffold(
          appBar: AppBar(
            title: Text(entityDisplayName(entity, l10n)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(
                  '${AppRoutes.customEntities}/${entity.id}/edit',
                  extra: entity,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: l10n.deleteCustomEntity,
                    content: l10n.deleteCustomEntityForever,
                  );
                  if (!ok) return;
                  try {
                    await ref
                        .read(customFeatureRepositoryProvider)
                        .deleteEntity(entity.id);
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push(
              '${AppRoutes.customEntities}/${entity.id}/fields/new',
            ),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.list_alt),
                  title: Text(entityPluralName(entity, l10n)),
                  subtitle: Text(l10n.openRecords),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '${AppRoutes.customEntities}/${entity.id}/records',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.permissions),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    '${AppRoutes.customEntities}/${entity.id}/permissions',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.fields,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (entity.fields.isEmpty)
                EmptyWidget(message: l10n.noCustomFieldsYet)
              else
                ...entity.fields.map(
                  (field) => Card(
                    child: ListTile(
                      title: Text(fieldDisplayName(field, l10n)),
                      subtitle: Text(
                        l10n.customFieldDataTypeLabel(fieldTypeKey(field.fieldType)),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        '${AppRoutes.customEntities}/${entity.id}/fields/${field.id}/edit',
                        extra: field,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
