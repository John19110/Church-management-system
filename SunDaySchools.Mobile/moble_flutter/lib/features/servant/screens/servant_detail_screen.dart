import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class ServantDetailScreen extends ConsumerWidget {
  final int id;
  const ServantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final servantAsync = ref.watch(servantDetailProvider(id));
    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.servant, id: id)),
    );
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.servantDetails)),
        body: const cw.LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.servantDetails)),
        body: cw.AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servantDetails),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: l10n.manageCustomFields,
              onPressed: () async {
                await context.push('/custom-fields/Servant');
                refreshEntityFormsAfterDefinitionChange(
                  ref,
                  UnifiedEntityNames.servant,
                );
                ref.invalidate(servantDetailProvider(id));
                ref.invalidate(
                  entityFormDataProvider((
                    entity: UnifiedEntityNames.servant,
                    id: id,
                  )),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final saved = await context.push<bool>('/servants/$id/edit');
              if (saved == true) {
                ref.invalidate(servantDetailProvider(id));
                ref.invalidate(
                  entityFormDataProvider((
                    entity: UnifiedEntityNames.servant,
                    id: id,
                  )),
                );
              }
            },
          ),
        ],
      ),
      body: servantAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(message: e.toString()),
        data: (servant) => formAsync.when(
          loading: () => const cw.LoadingWidget(),
          error: (e, _) => cw.AppErrorWidget(message: e.toString()),
          data: (formData) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppNetworkAvatar(
                  imageUrl: servant.imageUrl,
                  radius: 56,
                  placeholder: Text(
                    (servant.name?.isNotEmpty == true)
                        ? servant.name![0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  servant.name ?? 'Unknown',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                if (formData.fields.isEmpty)
                  EntityFieldsEmptyState(
                    entityName: UnifiedEntityNames.servant,
                    canManageDefinitions: canManage,
                  )
                else
                  UnifiedEntityDetailFields(fields: formData.fields),
              ],
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}
