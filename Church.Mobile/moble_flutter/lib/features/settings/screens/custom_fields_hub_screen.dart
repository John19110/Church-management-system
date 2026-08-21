import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../unified_form/models/unified_form_models.dart';

/// Central entry to per-entity custom field definition screens.
class CustomFieldsHubScreen extends ConsumerWidget {
  const CustomFieldsHubScreen({super.key});

  static const _scopes = <(String entity, IconData icon)>[
    (UnifiedEntityNames.member, Icons.person_outline),
    (UnifiedEntityNames.classroom, Icons.groups_outlined),
    (UnifiedEntityNames.servant, Icons.badge_outlined),
    (UnifiedEntityNames.meeting, Icons.event_outlined),
    (UnifiedEntityNames.church, Icons.account_balance_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;

    if (!AuthRoleUtils.canManageCustomFields(role)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.customFields)),
        body: Center(child: Text(l10n.notAuthorized)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customFields)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.customFieldsAdminDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final (entity, icon) in _scopes) ...[
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(l10n.entityDisplayName(entity)),
                subtitle: Text(l10n.customFieldsForEntity(entity)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/custom-fields/$entity'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
