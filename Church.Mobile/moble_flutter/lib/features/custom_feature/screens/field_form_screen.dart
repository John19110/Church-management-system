import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../settings/providers/language_settings_providers.dart';
import '../../settings/widgets/translated_name_fields.dart';
import '../models/custom_feature_models.dart';
import '../providers/custom_feature_providers.dart';
import '../utils/custom_feature_labels.dart';

class FieldFormScreen extends ConsumerStatefulWidget {
  final int entityId;
  final CustomEntityFieldReadDto? existing;

  const FieldFormScreen({super.key, required this.entityId, this.existing});

  @override
  ConsumerState<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _OptionRow {
  final TextEditingController value;
  final TextEditingController label;
  final TextEditingController labelAr;

  _OptionRow({String value = '', String label = '', String labelAr = ''})
    : value = TextEditingController(text: value),
      label = TextEditingController(text: label),
      labelAr = TextEditingController(text: labelAr);

  void dispose() {
    value.dispose();
    label.dispose();
    labelAr.dispose();
  }
}

class _FieldFormScreenState extends ConsumerState<FieldFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _displayNameAr = TextEditingController();
  final _placeholder = TextEditingController();
  CustomEntityFieldType _type = CustomEntityFieldType.text;
  bool _required = false;
  bool _unique = false;
  bool _searchable = false;
  bool _showOnList = true;
  bool _showOnForm = true;
  bool _showOnDetails = true;
  int? _targetEntityId;
  bool _saving = false;
  bool _namesSeeded = false;
  final List<_OptionRow> _options = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _displayName.text = existing.displayName;
      _displayNameAr.text = existing.displayNameAr ?? '';
      _placeholder.text = existing.placeholder ?? '';
      _type = existing.fieldType;
      _required = existing.isRequired;
      _unique = existing.isUnique;
      _searchable = existing.isSearchable;
      _showOnList = existing.showOnList;
      _showOnForm = existing.showOnForm;
      _showOnDetails = existing.showOnDetails;
      _targetEntityId = existing.targetEntityId;
      for (final option in existing.options) {
        _options.add(
          _OptionRow(
            value: option.value,
            label: option.displayText,
            labelAr: option.displayTextAr ?? '',
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _displayNameAr.dispose();
    _placeholder.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _scheduleSeedNames(AppLocalizations l10n) {
    if (_namesSeeded || !_isEdit) return;
    final existing = widget.existing;
    if (existing == null) return;
    final churchSnapshot = ref.read(churchLanguagesProvider).valueOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _namesSeeded) return;
      final church = TranslatedNameFields.resolveLanguages(
        church: churchSnapshot ?? ref.read(churchLanguagesProvider).valueOrNull,
        appLanguageCode: l10n.locale.languageCode,
      );
      TranslatedNameFields.seedFromStored(
        church: church,
        english: _displayName,
        arabic: _displayNameAr,
        displayName: existing.displayName,
        displayNameAr: existing.displayNameAr,
      );
      if (church.isArabicOnly) {
        for (final option in _options) {
          final ar = option.labelAr.text.trim();
          final en = option.label.text.trim();
          final primary = ar.isNotEmpty ? ar : en;
          option.label.text = primary;
          option.labelAr.text = primary;
        }
      }
      _namesSeeded = true;
    });
  }

  List<Map<String, dynamic>> _optionPayloads({required bool arabicOnly}) {
    return _options.map((o) {
      final label = o.label.text.trim();
      final labelAr = arabicOnly
          ? (o.labelAr.text.trim().isEmpty ? label : o.labelAr.text.trim())
          : o.labelAr.text.trim();
      final value = o.value.text.trim().isEmpty ? label : o.value.text.trim();
      return {
        'value': value,
        'displayText': label.isEmpty && arabicOnly ? labelAr : label,
        'displayTextAr': labelAr,
      };
    }).toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    final church = TranslatedNameFields.resolveLanguages(
      church: ref.read(churchLanguagesProvider).valueOrNull,
      appLanguageCode: l10n.locale.languageCode,
    );
    TranslatedNameFields.mirrorArabicOnlyName(
      church: church,
      english: _displayName,
      arabic: _displayNameAr,
    );
    if (church.isArabicOnly) {
      for (final option in _options) {
        if (option.labelAr.text.trim().isEmpty) {
          option.labelAr.text = option.label.text;
        }
        if (option.label.text.trim().isEmpty) {
          option.label.text = option.labelAr.text;
        }
      }
    }
    try {
      final body = <String, dynamic>{
        'displayName': _displayName.text.trim(),
        'displayNameAr': _displayNameAr.text.trim(),
        'placeholder': _placeholder.text.trim(),
        'isRequired': _required,
        'isUnique': _unique,
        'isSearchable': _searchable,
        'showOnList': _showOnList,
        'showOnForm': _showOnForm,
        'showOnDetails': _showOnDetails,
      };
      if (!_isEdit) {
        body['fieldType'] = _type.apiName;
        if (_type.isEntityRef) body['targetEntityId'] = _targetEntityId;
        if (_type.isSelect) {
          body['options'] = _optionPayloads(arabicOnly: church.isArabicOnly);
        }
      } else if (_type.isSelect) {
        body['options'] = _optionPayloads(arabicOnly: church.isArabicOnly);
      }

      final repo = ref.read(customFeatureRepositoryProvider);
      if (_isEdit) {
        await repo.updateField(id: widget.existing!.id, body: body);
      } else {
        await repo.createField(entityId: widget.entityId, body: body);
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
    ref.watch(churchLanguagesProvider);
    _scheduleSeedNames(l10n);
    final church = TranslatedNameFields.resolveLanguages(
      church: ref.watch(churchLanguagesProvider).valueOrNull,
      appLanguageCode: l10n.locale.languageCode,
    );
    final appIsArabic =
        l10n.locale.languageCode == OrganizationLanguages.arabic;
    final entityAsync = ref.watch(customEntityProvider(widget.entityId));
    final siblingEntities = entityAsync.maybeWhen(
      data: (entity) {
        final feature = ref.watch(customFeatureProvider(entity.featureId));
        return feature.maybeWhen(
          data: (value) =>
              value.entities.where((e) => e.id != widget.entityId).toList(),
          orElse: () => const <CustomEntityReadDto>[],
        );
      },
      orElse: () => const <CustomEntityReadDto>[],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCustomField : l10n.newCustomField),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: l10n.delete,
                  content: l10n.deleteCustomFieldForever,
                );
                if (!ok) return;
                try {
                  await ref
                      .read(customFeatureRepositoryProvider)
                      .deleteField(widget.existing!.id);
                  bumpCustomFeatures(ref);
                  if (context.mounted) context.pop();
                } catch (e) {
                  if (context.mounted) {
                    showErrorSnackbar(context, userFriendlyMessage(e, l10n));
                  }
                }
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: AppFormListView(
          children: [
            TranslatedNameFields(english: _displayName, arabic: _displayNameAr),
            DropdownButtonFormField<CustomEntityFieldType>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.fieldTypeLabel),
              items: CustomEntityFieldType.createChoices
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        l10n.customFieldDataTypeLabel(fieldTypeKey(type)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _isEdit
                  ? null
                  : (value) {
                      if (value != null) setState(() => _type = value);
                    },
            ),
            if (_type.isEntityRef)
              DropdownButtonFormField<int>(
                value: _targetEntityId,
                decoration: InputDecoration(labelText: l10n.targetEntity),
                items: siblingEntities
                    .map(
                      (entity) => DropdownMenuItem(
                        value: entity.id,
                        child: Text(entityDisplayName(entity, l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _targetEntityId = value),
                validator: (value) => value == null ? l10n.required : null,
              ),
            AppTextField(
              controller: _placeholder,
              label: l10n.placeholderLabel,
            ),
            SwitchListTile(
              title: Text(l10n.fieldStatusRequired),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            SwitchListTile(
              title: Text(l10n.uniqueField),
              value: _unique,
              onChanged: (v) => setState(() => _unique = v),
            ),
            SwitchListTile(
              title: Text(l10n.searchableField),
              value: _searchable,
              onChanged: (v) => setState(() => _searchable = v),
            ),
            SwitchListTile(
              title: Text(l10n.showOnList),
              value: _showOnList,
              onChanged: (v) => setState(() => _showOnList = v),
            ),
            SwitchListTile(
              title: Text(l10n.showOnForm),
              value: _showOnForm,
              onChanged: (v) => setState(() => _showOnForm = v),
            ),
            SwitchListTile(
              title: Text(l10n.showOnDetails),
              value: _showOnDetails,
              onChanged: (v) => setState(() => _showOnDetails = v),
            ),
            if (_type.isSelect) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.customFieldOptions,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ..._options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: church.isBilingual
                      ? Column(
                          children: appIsArabic
                              ? [
                                  AppTextField(
                                    controller: option.labelAr,
                                    label: '${l10n.displayNameArabicLabel} *',
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? l10n.arabicNameRequired
                                        : null,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppTextField(
                                    controller: option.label,
                                    label: '${l10n.displayNameEnglishLabel} *',
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? l10n.englishNameRequired
                                        : null,
                                  ),
                                ]
                              : [
                                  AppTextField(
                                    controller: option.label,
                                    label: '${l10n.displayNameEnglishLabel} *',
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? l10n.englishNameRequired
                                        : null,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  AppTextField(
                                    controller: option.labelAr,
                                    label: '${l10n.displayNameArabicLabel} *',
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? l10n.arabicNameRequired
                                        : null,
                                  ),
                                ],
                        )
                      : AppTextField(
                          controller: option.label,
                          label: '${l10n.nameLabel} *',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? l10n.displayNameRequired
                              : null,
                        ),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _options.add(_OptionRow())),
                icon: const Icon(Icons.add),
                label: Text(l10n.addOption),
              ),
            ],
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
