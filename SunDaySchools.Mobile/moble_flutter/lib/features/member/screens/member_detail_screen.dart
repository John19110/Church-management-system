import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/members_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../custom_field/providers/custom_field_cache_providers.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';

class MemberDetailScreen extends ConsumerWidget {
  final int id;
  const MemberDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (id <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.memberDetails)),
        body: cw.AppErrorWidget(
          message:
              'Invalid member id. Open this screen from the list after the API returns real ids.',
          onRetry: () {
            if (context.mounted) context.pop();
          },
        ),
      );
    }

    final formAsync = ref.watch(
      entityFormDataProvider((entity: UnifiedEntityNames.member, id: id)),
    );
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.memberDetails)),
        body: const cw.LoadingWidget(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.memberDetails)),
        body: cw.AppErrorWidget(message: e.toString()),
      ),
      data: (role) {
        final canManage = AuthRoleUtils.canManageCustomFields(role);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.memberDetails),
            actions: [
              if (canManage)
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: l10n.manageCustomFields,
                  onPressed: () async {
                    await context.push('/custom-fields/Member');
                    refreshEntityFormsAfterDefinitionChange(
                      ref,
                      UnifiedEntityNames.member,
                    );
                    ref.invalidate(
                      entityFormDataProvider((
                        entity: UnifiedEntityNames.member,
                        id: id,
                      )),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final saved = await context.push<bool>('/member/$id/edit');
                  if (saved == true) {
                    ref.invalidate(
                      entityFormDataProvider((
                        entity: UnifiedEntityNames.member,
                        id: id,
                      )),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final confirmed = await cw.showConfirmDialog(
                    context,
                    title: l10n.deleteMember,
                    content: l10n.confirmDeleteMember,
                  );
                  if (!confirmed) return;
                  try {
                    await ref.read(membersRepositoryProvider).delete(id);
                    if (context.mounted) {
                      cw.showSuccessSnackbar(
                        context,
                        l10n.memberDeletedSuccessfully,
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      cw.showErrorSnackbar(context, e.toString());
                    }
                  }
                },
              ),
            ],
          ),
          body: formAsync.when(
            loading: () => const cw.LoadingWidget(),
            error: (e, _) => cw.AppErrorWidget(
              message: e.toString(),
              onRetry: () => ref.invalidate(
                entityFormDataProvider((
                  entity: UnifiedEntityNames.member,
                  id: id,
                )),
              ),
            ),
            data: (formData) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  UnifiedEntityDetailHeader(
                    entityName: UnifiedEntityNames.member,
                    fields: formData.fields,
                  ),
                  const SizedBox(height: 16),
                  if (formData.fields.isEmpty)
                    EntityFieldsEmptyState(
                      entityName: UnifiedEntityNames.member,
                      canManageDefinitions: canManage,
                    )
                  else
                    UnifiedEntityDetailFields(fields: formData.fields),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
