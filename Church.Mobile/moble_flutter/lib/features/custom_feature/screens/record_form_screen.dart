import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/custom_feature_models.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';
import '../widgets/dynamic_record_form_fields.dart';

class RecordFormScreen extends ConsumerStatefulWidget {
  final int entityId;
  final int? recordId;

  const RecordFormScreen({
    super.key,
    required this.entityId,
    this.recordId,
  });

  @override
  ConsumerState<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends ConsumerState<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _values = {};
  bool _hydrated = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entityAsync = ref.watch(customEntityProvider(widget.entityId));
    final recordAsync = widget.recordId == null
        ? null
        : ref.watch(customRecordProvider((widget.entityId, widget.recordId!)));

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
        if (recordAsync != null) {
          return recordAsync.when(
            loading: () => Scaffold(
              appBar: AppBar(title: Text(entityDisplayName(entity, l10n))),
              body: const LoadingWidget(useSkeleton: true),
            ),
            error: (e, _) => Scaffold(
              appBar: AppBar(title: Text(entityDisplayName(entity, l10n))),
              body: AppErrorWidget(
                message: userFriendlyMessage(e, l10n),
                onRetry: () => ref.invalidate(
                  customRecordProvider((widget.entityId, widget.recordId!)),
                ),
              ),
            ),
            data: (record) => _form(context, l10n, entity, record),
          );
        }
        return _form(context, l10n, entity, null);
      },
    );
  }

  Widget _form(
    BuildContext context,
    AppLocalizations l10n,
    CustomEntityReadDto entity,
    CustomEntityRecordReadDto? record,
  ) {
    if (!_hydrated) {
      _hydrated = true;
      if (record != null) _values.addAll(record.values);
    }

    final targetIds = entity.fields
        .where((f) => f.targetEntityId != null)
        .map((f) => f.targetEntityId!)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          record == null
              ? '${l10n.newRecord} — ${entityDisplayName(entity, l10n)}'
              : '${l10n.editRecord} — ${entityDisplayName(entity, l10n)}',
        ),
      ),
      body: Form(
        key: _formKey,
        child: AppFormListView(
          children: [
            DynamicRecordFormFields(
              entity: entity,
              values: _values,
              onChanged: () => setState(() {}),
              referenceRecords: _loadReferences(targetIds),
            ),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _saving = true);
                      try {
                        await ref.read(customFeatureRepositoryProvider).saveRecord(
                              entityId: widget.entityId,
                              recordId: widget.recordId,
                              values: _values,
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
      ),
    );
  }

  List<CustomEntityRecordReadDto> _loadReferences(Set<int> targetIds) {
    final records = <CustomEntityRecordReadDto>[];
    for (final id in targetIds) {
      final async =
          ref.watch(customRecordsProvider(CustomRecordListKey(id, '')));
      async.whenData((page) => records.addAll(page.items));
    }
    return records;
  }
}
