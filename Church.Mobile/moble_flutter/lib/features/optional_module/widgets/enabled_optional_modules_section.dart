import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../models/optional_module_models.dart';
import '../providers/optional_module_providers.dart';

/// Dynamic nav section for predefined optional modules that are enabled
/// for the current organization. Central place for module visibility.
class EnabledOptionalModulesSection extends ConsumerWidget {
  const EnabledOptionalModulesSection({super.key});

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  String? _routeFor(String moduleId) {
    switch (moduleId) {
      case OptionalModuleIds.stock:
        return AppRoutes.stock;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(enabledOptionalModulesProvider);
    final isArabic = l10n.locale.languageCode == 'ar';

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(userFriendlyMessage(e, l10n)),
      ),
      data: (modules) {
        if (modules.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.optionalFeatures,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final module in modules)
              Card(
                child: ListTile(
                  leading: Icon(_iconFor(module.icon)),
                  title: Text(module.displayName(isArabic)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final route = _routeFor(module.id);
                    if (route != null) context.push(route);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
