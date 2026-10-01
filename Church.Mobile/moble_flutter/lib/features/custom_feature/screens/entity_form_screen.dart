import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../settings/models/language_settings.dart';
import '../../settings/providers/language_settings_providers.dart';
import '../../settings/widgets/translated_name_fields.dart';
import '../models/custom_feature_models.dart';
import '../providers/custom_feature_providers.dart';

class EntityFormScreen extends ConsumerStatefulWidget {
  final int featureId;
  final CustomEntityReadDto? existing;

  const EntityFormScreen({
    super.key,
    required this.featureId,
    this.existing,
  });

  @override
  ConsumerState<EntityFormScreen> createState() => _EntityFormScreenState();
}

class _EntityFormScreenState extends ConsumerState<EntityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _displayNameAr = TextEditingController();
  final _plural = TextEditingController();
  final _pluralAr = TextEditingController();
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
      _plural.text = existing.pluralDisplayName;
      _pluralAr.text = existing.pluralDisplayNameAr ?? '';
      _isActive = existing.isActive;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _displayNameAr.dispose();
    _plural.dispose();
    _pluralAr.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final church = ref.read(churchLanguagesProvider).valueOrNull ??
        ChurchLanguages.bilingual(isConfigured: true);
    TranslatedNameFields.mirrorArabicOnlyName(
      church: church,
      english: _displayName,
      arabic: _displayNameAr,
    );
    TranslatedNameFields.mirrorArabicOnlyName(
      church: church,
      english: _plural,
      arabic: _pluralAr,
    );
    try {
      final repo = ref.read(customFeatureRepositoryProvider);
      if (_isEdit) {
        await repo.updateEntity(
          id: widget.existing!.id,
          displayName: _displayName.text.trim(),
          displayNameAr: _displayNameAr.text.trim(),
          pluralDisplayName: _plural.text.trim(),
          pluralDisplayNameAr: _pluralAr.text.trim(),
          isActive: _isActive,
        );
      } else {
        await repo.createEntity(
          featureId: widget.featureId,
          displayName: _displayName.text.trim(),
          displayNameAr: _displayNameAr.text.trim(),
          pluralDisplayName: _plural.text.trim(),
          pluralDisplayNameAr: _pluralAr.text.trim(),
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
        title: Text(_isEdit ? l10n.editCustomEntity : l10n.newCustomEntity),
      ),
      body: Form(
        key: _formKey,
        child: AppFormListView(
          children: [
            TranslatedNameFields(
              english: _displayName,
              arabic: _displayNameAr,
            ),
            const SizedBox(height: AppSpacing.sm),
            TranslatedNameFields(
              english: _plural,
              arabic: _pluralAr,
              englishLabel: l10n.pluralDisplayNameEnglish,
              arabicLabel: l10n.pluralDisplayNameArabic,
              singleLanguageLabel: l10n.pluralDisplayNameEnglish,
            ),
            if (_isEdit)
              SwitchListTile(
                title: Text(l10n.active),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
