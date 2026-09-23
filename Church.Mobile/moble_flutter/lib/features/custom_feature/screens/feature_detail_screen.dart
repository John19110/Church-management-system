import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class FeatureDetailScreen extends ConsumerWidget {
  final int featureId;

  const FeatureDetailScreen({super.key, required this.featureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(customFeatureProvider(featureId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: const LoadingWidget(useSkeleton: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customFeatureProvider(featureId)),
        ),
      ),
      data: (feature) {
        return Scaffold(
          appBar: AppBar(
            title: Text(featureDisplayName(feature, l10n)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(
                  '${AppRoutes.customFeaturesHub}/${feature.id}/edit',
                  extra: feature,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showConfirmDialog(
                    context,
                    title: l10n.deleteCustomFeature,
                    content: l10n.deleteCustomFeatureForever,
                  );
                  if (!ok) return;
                  try {
                    await ref
                        .read(customFeatureRepositoryProvider)
                        .deleteFeature(feature.id);
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
              '${AppRoutes.customFeaturesHub}/${feature.id}/entities/new',
            ),
            child: const Icon(Icons.add),
          ),
          body: feature.entities.isEmpty
              ? EmptyWidget(message: l10n.noCustomEntitiesYet)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: feature.entities.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final entity = feature.entities[index];
                    return Card(
                      child: ListTile(
                        title: Text(entityPluralName(entity, l10n)),
                        subtitle: Text(
                          entity.isActive ? l10n.active : l10n.inactive,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '${AppRoutes.customEntities}/${entity.id}',
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
