import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_network_avatar.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.servantDetails),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await context.push('/servants/$id/edit');
              ref.invalidate(servantDetailProvider(id));
              ref.invalidate(entityFormDataProvider((entity: UnifiedEntityNames.servant, id: id)));
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
                UnifiedEntityDetailFields(fields: formData.fields),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
