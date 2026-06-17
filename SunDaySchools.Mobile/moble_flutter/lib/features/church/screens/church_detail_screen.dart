import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;

/// Displays the current tenant church using unified form-data (all SQL columns).
class ChurchDetailScreen extends ConsumerWidget {
  final int churchId;

  const ChurchDetailScreen({super.key, required this.churchId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.church, id: churchId)),
    );
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.churchName)),
        body: const cw.LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.churchName)),
        body: cw.AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.churchName),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: () async {
                    await context.push('/custom-fields/${UnifiedEntityNames.church}');
                    if (context.mounted) {
                      refreshEntityFormsAfterDefinitionChange(
                        ref,
                        UnifiedEntityNames.church,
                      );
                      ref.invalidate(
                        entityFormDataProvider((
                          entity: UnifiedEntityNames.church,
                          id: churchId,
                        )),
                      );
                    }
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final saved = await context.push<bool>(
                    '/church/$churchId/edit',
                  );
                  if (saved == true) {
                    ref.invalidate(
                      entityFormDataProvider((
                        entity: UnifiedEntityNames.church,
                        id: churchId,
                      )),
                    );
                  }
                },
              ),
            ],
          ),
          body: formAsync.when(
            loading: () => const cw.LoadingWidget(),
            error: (e, _) => cw.AppErrorWidget(message: e.toString()),
            data: (form) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                UnifiedEntityDetailHeader(
                  entityName: UnifiedEntityNames.church,
                  fields: form.fields,
                ),
                const SizedBox(height: 16),
                UnifiedEntityDetailFields(fields: form.fields),
              ],
            ),
          ),
        );
      },
    );
  }
}
