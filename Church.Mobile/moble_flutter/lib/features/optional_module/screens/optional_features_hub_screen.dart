import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/optional_module_models.dart';
import '../providers/optional_module_providers.dart';

class OptionalFeaturesHubScreen extends ConsumerWidget {
  const OptionalFeaturesHubScreen({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final canManage = AuthRoleUtils.canManageCustomFields(role);
    final async = ref.watch(optionalModulesProvider);
    final isArabic = l10n.locale.languageCode == 'ar';

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.optionalFeatures)),
        body: Center(child: Text(l10n.notAuthorized)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.optionalFeatures)),
      body: async.when(
        loading: () => const LoadingWidget(useSkeleton: true),
        error: (e, _) => AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => bumpOptionalModules(ref),
        ),
        data: (modules) {
          if (modules.isEmpty) {
            return EmptyWidget(message: l10n.noOptionalModulesYet);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: modules.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(l10n.optionalFeaturesLanding),
                );
              }
              final module = modules[index - 1];
              return _ModuleCard(
                module: module,
                isArabic: isArabic,
                icon: _iconFor(module.icon),
                onChanged: (enabled) => _toggle(context, ref, module, enabled),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    OptionalModuleDto module,
    bool enabled,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(optionalModuleRepositoryProvider).setEnabled(
            moduleId: module.id,
            isEnabled: enabled,
          );
      bumpOptionalModules(ref);
      if (module.id == OptionalModuleIds.stock) {
        bumpStockItems(ref);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyMessage(e, l10n))),
      );
      bumpOptionalModules(ref);
    }
  }
}

class _ModuleCard extends StatelessWidget {
  final OptionalModuleDto module;
  final bool isArabic;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  const _ModuleCard({
    required this.module,
    required this.isArabic,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon),
        title: Text(module.displayName(isArabic)),
        subtitle: Text(module.displayDescription(isArabic)),
        value: module.isEnabled,
        onChanged: onChanged,
      ),
    );
  }
}
