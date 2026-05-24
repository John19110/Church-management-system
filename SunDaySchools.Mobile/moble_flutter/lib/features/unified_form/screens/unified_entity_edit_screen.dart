import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/common_widgets.dart';
import '../models/unified_form_models.dart';
import '../providers/unified_form_providers.dart';
import '../utils/unified_form_controller.dart';
import '../widgets/unified_entity_form.dart';

/// Generic edit screen driven by unified form-data API.
class UnifiedEntityEditScreen extends ConsumerStatefulWidget {
  final String entityName;
  final int entityId;
  final String? title;

  const UnifiedEntityEditScreen({
    super.key,
    required this.entityName,
    required this.entityId,
    this.title,
  });

  @override
  ConsumerState<UnifiedEntityEditScreen> createState() =>
      _UnifiedEntityEditScreenState();
}

class _UnifiedEntityEditScreenState extends ConsumerState<UnifiedEntityEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = UnifiedFormController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(List<UnifiedFieldDefinitionDto> fields) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(unifiedFormRepositoryProvider).saveFormData(
            widget.entityName,
            widget.entityId,
            _controller.buildSavePayload(fields),
          );
      ref.invalidate(
        entityFormDataProvider((entity: widget.entityName, id: widget.entityId)),
      );
      if (mounted) {
        showSuccessSnackbar(context, 'Saved');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formAsync = ref.watch(
      entityFormDataProvider((entity: widget.entityName, id: widget.entityId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? '${widget.entityName} fields')),
      body: formAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (data) {
          if (!_initialized) {
            _controller.initializeFromFields(data.fields, withValues: data.fields);
            _initialized = true;
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                UnifiedEntityForm(fields: data.fields, controller: _controller),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : FilledButton(
                        onPressed: () => _save(data.fields),
                        child: const Text('Save'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}
