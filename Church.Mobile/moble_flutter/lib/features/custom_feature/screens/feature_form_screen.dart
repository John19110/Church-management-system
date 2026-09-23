import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/custom_feature_models.dart';
import '../providers/custom_feature_providers.dart';

class FeatureFormScreen extends ConsumerStatefulWidget {
  final CustomFeatureReadDto? existing;

  const FeatureFormScreen({super.key, this.existing});

  @override
  ConsumerState<FeatureFormScreen> createState() => _FeatureFormScreenState();
}

class _FeatureFormScreenState extends ConsumerState<FeatureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _displayNameAr = TextEditingController();
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _displayName.text = existing.displayName;
      _displayNameAr.text = existing.displayNameAr ?? '';
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _displayNameAr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = ref.read(customFeatureRepositoryProvider);
      if (_isEdit) {
        await repo.updateFeature(
          id: widget.existing!.id,
          displayName: _displayName.text.trim(),
          displayNameAr: _displayNameAr.text.trim(),
          isActive: _isActive,
        );
      } else {
        await repo.createFeature(
          displayName: _displayName.text.trim(),
          displayNameAr: _displayNameAr.text.trim(),
        );
      }
      bumpCustomFeatures(ref);
      if (!mounted) return;
      showSuccessSnackbar(context, l10n.changesSaved);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCustomFeature : l10n.newCustomFeature),
      ),
      body: Form(
        key: _formKey,
        child: AppFormListView(
          children: [
          AppTextField(
            controller: _displayName,
            label: l10n.displayNameEnglishLabel,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
          AppTextField(
            controller: _displayNameAr,
            label: l10n.displayNameArabicLabel,
          ),
          if (_isEdit)
            SwitchListTile(
              title: Text(l10n.active),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
        ),
      ),
    );
  }
}
