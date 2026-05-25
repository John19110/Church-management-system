import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';
import '../utils/custom_field_l10n.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';

class CustomFieldDefinitionFormScreen extends ConsumerStatefulWidget {
  final String entityName;
  final CustomFieldDefinitionReadDto? existing;

  const CustomFieldDefinitionFormScreen({
    super.key,
    required this.entityName,
    this.existing,
  });

  @override
  ConsumerState<CustomFieldDefinitionFormScreen> createState() =>
      _CustomFieldDefinitionFormScreenState();
}

class _CustomFieldDefinitionFormScreenState
    extends ConsumerState<CustomFieldDefinitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  CustomFieldDataType _dataType = CustomFieldDataType.text;
  bool _isRequired = false;
  bool _isReadOnly = false;
  bool _loading = false;

  final List<({TextEditingController value, TextEditingController label})>
      _options = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _displayNameController.text = e.displayName;
      _dataType = e.dataType;
      _isRequired = e.isRequired;
      _isReadOnly = e.isReadOnly;
      for (final o in e.options) {
        _options.add((
          value: TextEditingController(text: o.value),
          label: TextEditingController(text: o.displayText),
        ));
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    for (final o in _options) {
      o.value.dispose();
      o.label.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCustomField : l10n.newCustomField),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _displayNameController,
              label: l10n.displayNameLabel,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? l10n.displayNameRequired : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomFieldDataType>(
              value: _dataType,
              decoration: InputDecoration(labelText: l10n.fieldTypeLabel),
              items: CustomFieldDataType.values
                  .where((t) => t != CustomFieldDataType.unknown)
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(l10n.labelForDataType(t)),
                      ))
                  .toList(),
              onChanged: _isEdit
                  ? null
                  : (v) => setState(() => _dataType = v ?? _dataType),
            ),
            SwitchListTile(
              title: Text(l10n.fieldRequiredLabel),
              value: _isRequired,
              onChanged: (v) => setState(() => _isRequired = v),
            ),
            SwitchListTile(
              title: Text(l10n.fieldReadOnlyLabel),
              value: _isReadOnly,
              onChanged: (v) => setState(() => _isReadOnly = v),
            ),
            if (_dataType == CustomFieldDataType.singleSelect ||
                _dataType == CustomFieldDataType.multiSelect) ...[
              const SizedBox(height: 8),
              Text(
                l10n.customFieldOptions,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ..._options.map((o) => Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: o.value,
                          label: l10n.optionValueLabel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: o.label,
                          label: l10n.optionLabelLabel,
                        ),
                      ),
                    ],
                  )),
              TextButton.icon(
                onPressed: () => setState(() {
                  _options.add((
                    value: TextEditingController(),
                    label: TextEditingController(),
                  ));
                }),
                icon: const Icon(Icons.add),
                label: Text(l10n.addOption),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? l10n.saveLabel : l10n.createField),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final options = _buildOptions();
    if ((_dataType == CustomFieldDataType.singleSelect ||
            _dataType == CustomFieldDataType.multiSelect) &&
        (options == null || options.isEmpty)) {
      showErrorSnackbar(context, l10n.selectOptionsRequired);
      return;
    }

    setState(() => _loading = true);

    try {
      final repo = ref.read(customFieldRepositoryProvider);
      if (_isEdit) {
        await repo.updateDefinition(
          widget.existing!.id,
          CustomFieldDefinitionUpdateDto(
            displayName: _displayNameController.text.trim(),
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            options: options,
          ),
        );
      } else {
        await repo.createDefinition(
          CustomFieldDefinitionCreateDto(
            displayName: _displayNameController.text.trim(),
            entityName: widget.entityName,
            dataType: customFieldDataTypeToApi(_dataType),
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            options: options,
          ),
        );
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<CustomFieldOptionDto>? _buildOptions() {
    if (_dataType != CustomFieldDataType.singleSelect &&
        _dataType != CustomFieldDataType.multiSelect) {
      return null;
    }
    return _options
        .where((o) => o.value.text.trim().isNotEmpty)
        .map((o) => CustomFieldOptionDto(
              value: o.value.text.trim(),
              displayText: o.label.text.trim().isEmpty
                  ? o.value.text.trim()
                  : o.label.text.trim(),
            ))
        .toList();
  }
}
