import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/customization_language_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class FeaturesHubScreen extends ConsumerWidget {
  const FeaturesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    if (!AuthRoleUtils.canManageCustomFields(role)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: Center(child: Text(l10n.notAuthorized)),
      );
    }

    final async = ref.watch(customFeaturesProvider(true));
    final customLang = ref.watch(resolvedCustomizationLanguageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customFeatures)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.customFeatureNew),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const LoadingWidget(useSkeleton: true),
        error: (e, _) => AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customFeaturesProvider(true)),
        ),
        data: (features) {
          if (features.isEmpty) {
            return EmptyWidget(
              title: l10n.noCustomFeaturesYet,
              message: l10n.noCustomFeaturesYetBody,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final feature = features[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    feature.isActive
                        ? Icons.extension
                        : Icons.extension_off_outlined,
                  ),
                  title: Text(
                    featureDisplayName(
                      feature,
                      l10n,
                      languageCode: customLang,
                    ),
                  ),
                  subtitle: Text(
                    [
                      feature.isActive ? l10n.active : l10n.inactive,
                      if ((feature.displayNameAr ?? '').trim().isEmpty)
                        l10n.arabicTranslationMissing
                      else
                        '${l10n.englishShort} ✓   ${l10n.arabicShort} ✓',
                    ].join('\n'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('${AppRoutes.customFeaturesHub}/${feature.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
