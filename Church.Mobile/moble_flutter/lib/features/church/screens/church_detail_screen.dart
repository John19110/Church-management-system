import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.churchName),
        actions: [
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
        error: (e, _) =>
            cw.AppErrorWidget(message: userFriendlyMessage(e, l10n)),
        data: (form) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            UnifiedEntityDetailHeader(
              entityName: UnifiedEntityNames.church,
              fields: form.fields,
            ),
            const SizedBox(height: 16),
            UnifiedEntityDetailFields(
              entityName: UnifiedEntityNames.church,
              fields: form.fields,
            ),
          ],
        ),
      ),
    );
  }
}
