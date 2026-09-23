import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class EnabledFeaturesSection extends ConsumerWidget {
  const EnabledFeaturesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final async = ref.watch(customFeaturesProvider(false));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(userFriendlyMessage(e, l10n)),
      data: (features) {
        final visible = features.where((f) => f.isActive).toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customFeatures,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final feature in visible)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.extension),
                  title: Text(featureDisplayName(feature, l10n)),
                  children: [
                    for (final entity in feature.entities.where((e) => e.isActive))
                      ListTile(
                        title: Text(entityPluralName(entity, l10n)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '${AppRoutes.customEntities}/${entity.id}/records',
                        ),
                      ),
                    if (role == 'admin' || role == 'superadmin')
                      ListTile(
                        title: Text(l10n.manageFeature),
                        trailing: const Icon(Icons.settings_outlined),
                        onTap: () => context.push(
                          '${AppRoutes.customFeaturesHub}/${feature.id}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
