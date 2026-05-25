import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';

/// Shown when an entity has no admin-configured custom field definitions yet.
class EntityFieldsEmptyState extends StatelessWidget {
  final String entityName;
  final String? configurationHint;
  final bool canManageDefinitions;

  const EntityFieldsEmptyState({
    super.key,
    required this.entityName,
    this.configurationHint,
    this.canManageDefinitions = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hint = configurationHint ?? l10n.entityFieldsNotConfigured;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.tune,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.configureEntityAttributesTitle(entityName),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (canManageDefinitions) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.push('/custom-fields/$entityName'),
                icon: const Icon(Icons.settings),
                label: Text(l10n.manageCustomFields),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
