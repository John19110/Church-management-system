import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import '../utils/field_display_label.dart';

class FieldDefinitionCard extends StatelessWidget {
  final CustomFieldDefinitionReadDto definition;
  final VoidCallback? onTap;
  final VoidCallback? onDeactivate;
  final VoidCallback? onReactivate;
  final VoidCallback? onDeletePermanently;

  const FieldDefinitionCard({
    super.key,
    required this.definition,
    this.onTap,
    this.onDeactivate,
    this.onReactivate,
    this.onDeletePermanently,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isSystem = definition.isBuiltIn || definition.isSystemField;
    final displayLabel = localizedFieldDisplayLabel(definition, l10n);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: isSystem
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayLabel,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (isSystem)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: Chip(
                  label: Text(
                    l10n.systemFieldBadge,
                    style: theme.textTheme.labelSmall,
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              localizedFieldCardSubtitle(definition, l10n),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              definition.isRequired
                  ? l10n.fieldStatusRequired
                  : l10n.fieldStatusOptional,
              style: theme.textTheme.bodySmall?.copyWith(
                color: definition.isRequired
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (definition.isHidden)
              Text(
                l10n.fieldHiddenInForms,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (!definition.isActive)
              Text(
                l10n.fieldInactive,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
        trailing: _buildTrailing(l10n, theme),
      ),
    );
  }

  Widget _buildTrailing(AppLocalizations l10n, ThemeData theme) {
    final menuItems = <PopupMenuEntry<String>>[];

    if (definition.isActive &&
        onDeactivate != null &&
        definition.isDeletable) {
      menuItems.add(
        PopupMenuItem(
          value: 'deactivate',
          child: Row(
            children: [
              const Icon(Icons.visibility_off_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.deactivate),
            ],
          ),
        ),
      );
    }

    if (!definition.isActive && onReactivate != null) {
      menuItems.add(
        PopupMenuItem(
          value: 'reactivate',
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.reactivate),
            ],
          ),
        ),
      );
    }

    if (onDeletePermanently != null && definition.isDeletable) {
      menuItems.add(
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_forever_outlined,
                  size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text(
                l10n.deletePermanently,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      );
    }

    if (menuItems.isEmpty) {
      return Icon(
        definition.isActive ? Icons.chevron_right : Icons.visibility_off,
        color: definition.isActive ? null : theme.colorScheme.outline,
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: l10n.fieldMoreOptions,
      onSelected: (value) {
        switch (value) {
          case 'deactivate':
            onDeactivate?.call();
            break;
          case 'reactivate':
            onReactivate?.call();
            break;
          case 'delete':
            onDeletePermanently?.call();
            break;
        }
      },
      itemBuilder: (context) => menuItems,
    );
  }
}
