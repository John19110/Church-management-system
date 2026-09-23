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
import '../utils/custom_feature_labels.dart';

class FieldFormScreen extends ConsumerStatefulWidget {
  final int entityId;
  final CustomEntityFieldReadDto? existing;

  const FieldFormScreen({
    super.key,
    required this.entityId,
    this.existing,
  });

  @override
  ConsumerState<FieldFormScreen> createState() => _FieldFormScreenState();
}

class _OptionRow {
  final TextEditingController value;
  final TextEditingController label;
  final TextEditingController labelAr;

  _OptionRow({
    String value = '',
    String label = '',
    String labelAr = '',
  })  : value = TextEditingController(text: value),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
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
          body['options'] = _options
              .map(
                (o) => {
                  'value': o.value.text.trim().isEmpty
                      ? o.label.text.trim()
                      : o.value.text.trim(),
                  'displayText': o.label.text.trim(),
                  'displayTextAr': o.labelAr.text.trim(),
                },
              )
              .toList();
        }
      } else if (_type.isSelect) {
        body['options'] = _options
            .map(
              (o) => {
                'value': o.value.text.trim().isEmpty
                    ? o.label.text.trim()
                    : o.value.text.trim(),
                'displayText': o.label.text.trim(),
                'displayTextAr': o.labelAr.text.trim(),
              },
            )
            .toList();
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
            DropdownButtonFormField<CustomEntityFieldType>(
              value: _type,
              decoration: InputDecoration(labelText: l10n.fieldTypeLabel),
              items: CustomEntityFieldType.createChoices
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(l10n.customFieldDataTypeLabel(fieldTypeKey(type))),
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
                validator: (value) =>
                    value == null ? l10n.required : null,
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
              const SizedBox(height: 8),
              Text(l10n.customFieldOptions, style: Theme.of(context).textTheme.titleMedium),
              ..._options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: option.label,
                          label: l10n.displayNameEnglishLabel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: option.labelAr,
                          label: l10n.displayNameArabicLabel,
                        ),
                      ),
                    ],
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
