import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/custom_feature_models.dart';
import '../providers/custom_feature_providers.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  final int entityId;

  const PermissionsScreen({super.key, required this.entityId});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  List<CustomEntityPermissionDto>? _draft;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(customEntityProvider(widget.entityId));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.permissions)),
        body: const LoadingWidget(useSkeleton: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.permissions)),
        body: AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customEntityProvider(widget.entityId)),
        ),
      ),
      data: (entity) {
        _draft ??= entity.permissions
            .map(
              (p) => CustomEntityPermissionDto(
                roleName: p.roleName,
                canCreate: p.canCreate,
                canRead: p.canRead,
                canUpdate: p.canUpdate,
                canDelete: p.canDelete,
              ),
            )
            .toList();
        final draft = _draft!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.permissions)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < draft.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft[i].roleName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        CheckboxListTile(
                          title: Text(l10n.permissionRead),
                          value: draft[i].canRead,
                          onChanged: (v) => setState(() {
                            draft[i] = draft[i].copyWith(canRead: v ?? false);
                          }),
                        ),
                        CheckboxListTile(
                          title: Text(l10n.permissionCreate),
                          value: draft[i].canCreate,
                          onChanged: (v) => setState(() {
                            draft[i] = draft[i].copyWith(canCreate: v ?? false);
                          }),
                        ),
                        CheckboxListTile(
                          title: Text(l10n.permissionUpdate),
                          value: draft[i].canUpdate,
                          onChanged: (v) => setState(() {
                            draft[i] = draft[i].copyWith(canUpdate: v ?? false);
                          }),
                        ),
                        CheckboxListTile(
                          title: Text(l10n.permissionDelete),
                          value: draft[i].canDelete,
                          onChanged: (v) => setState(() {
                            draft[i] = draft[i].copyWith(canDelete: v ?? false);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(customFeatureRepositoryProvider)
                              .updatePermissions(
                                entityId: widget.entityId,
                                permissions: draft,
                              );
                          bumpCustomFeatures(ref);
                          if (context.mounted) {
                            showSuccessSnackbar(context, l10n.changesSaved);
                            context.pop();
                          }
                        } catch (e) {
                          if (context.mounted) {
                            showErrorSnackbar(
                              context,
                              userFriendlyMessage(e, l10n),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(l10n.save),
              ),
            ],
          ),
        );
      },
    );
  }
}
