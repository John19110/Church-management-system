import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/app_list_row.dart';
import '../../../shared/widgets/app_search_field.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class RecordListScreen extends ConsumerStatefulWidget {
  final int entityId;

  const RecordListScreen({super.key, required this.entityId});

  @override
  ConsumerState<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends ConsumerState<RecordListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final entityAsync = ref.watch(customEntityProvider(widget.entityId));
    final recordsAsync = ref.watch(
      customRecordsProvider(CustomRecordListKey(widget.entityId, _query)),
    );

    return entityAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: const LoadingWidget(useSkeleton: true),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.customFeatures)),
        body: AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customEntityProvider(widget.entityId)),
        ),
      ),
      data: (entity) {
        final permission = entity.permissionForRole(role);
        return Scaffold(
          appBar: AppBar(title: Text(entityPluralName(entity, l10n))),
          floatingActionButton: permission?.canCreate == true
              ? FloatingActionButton(
                  onPressed: () => context.push(
                    '${AppRoutes.customEntities}/${entity.id}/records/new',
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppSearchField(
                  controller: _search,
                  hint: l10n.search,
                  onChanged: (value) => setState(() => _query = value.trim()),
                ),
              ),
              Expanded(
                child: recordsAsync.when(
                  loading: () => const LoadingWidget(useSkeleton: true),
                  error: (e, _) => AppErrorWidget(
                    message: userFriendlyMessage(e, l10n),
                    onRetry: () => ref.invalidate(
                      customRecordsProvider(
                        CustomRecordListKey(widget.entityId, _query),
                      ),
                    ),
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return EmptyWidget(message: l10n.noRecordsYet);
                    }
                    return RefreshIndicator(
                      onRefresh: () async => bumpCustomFeatures(ref),
                      child: ListView.builder(
                        itemCount: page.items.length,
                        itemBuilder: (_, index) {
                          final record = page.items[index];
                          return AppListRow(
                            title: recordTitle(record, entity, l10n),
                            subtitle: l10n.recordsCount(page.total),
                            onTap: permission?.canRead == true
                                ? () => context.push(
                                      '${AppRoutes.customEntities}/${entity.id}/records/${record.id}',
                                    )
                                : null,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
