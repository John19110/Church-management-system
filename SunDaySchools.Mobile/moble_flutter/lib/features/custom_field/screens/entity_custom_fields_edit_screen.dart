import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';
import '../widgets/dynamic_custom_fields_form.dart';
import '../../../shared/widgets/common_widgets.dart';

/// Edit custom field values for any entity (Classroom, Meeting, etc.).
class EntityCustomFieldsEditScreen extends ConsumerStatefulWidget {
  final String entityName;
  final int entityId;
  final String? title;

  const EntityCustomFieldsEditScreen({
    super.key,
    required this.entityName,
    required this.entityId,
    this.title,
  });

  @override
  ConsumerState<EntityCustomFieldsEditScreen> createState() =>
      _EntityCustomFieldsEditScreenState();
}

class _EntityCustomFieldsEditScreenState
    extends ConsumerState<EntityCustomFieldsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = DynamicCustomFieldsController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await saveCustomFieldsForEntity(
        ref: ref,
        entityName: widget.entityName,
        entityId: widget.entityId,
        controller: _controller,
      );
      ref.invalidate(
        entityCustomFieldsProvider((
          entity: widget.entityName,
          id: widget.entityId,
        )),
      );
      if (mounted) {
        showSuccessSnackbar(context, 'Additional fields saved');
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
    final title = widget.title ?? '${widget.entityName} — additional fields';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DynamicCustomFieldsForm(
              entityName: widget.entityName,
              entityId: widget.entityId,
              controller: _controller,
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _save,
                    child: const Text('Save additional fields'),
                  ),
          ],
        ),
      ),
    );
  }
}
