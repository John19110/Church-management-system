import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/custom_field_models.dart';
import '../providers/custom_field_cache_providers.dart';
import '../providers/custom_field_providers.dart';
import '../utils/custom_field_l10n.dart';
import '../utils/field_display_label.dart';
import '../utils/field_position_utils.dart';
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

class _OptionControllers {
  final int? id;
  final TextEditingController value;
  final TextEditingController label;

  const _OptionControllers({
    this.id,
    required this.value,
    required this.label,
  });
}

class _CustomFieldDefinitionFormScreenState
    extends ConsumerState<CustomFieldDefinitionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _displayNameArController = TextEditingController();
  final _placeholderController = TextEditingController();
  final _validationRegexController = TextEditingController();
  CustomFieldDataType _dataType = CustomFieldDataType.text;
  bool _isRequired = false;
  bool _isReadOnly = false;
  bool _isHidden = false;
  bool _loading = false;
  int? _displayPosition;

  final List<_OptionControllers> _options = [];

  bool get _isEdit => widget.existing != null;

  bool get _isSystemField =>
      widget.existing?.isBuiltIn == true ||
      widget.existing?.isSystemField == true;

  bool get _isCriticalField => widget.existing?.isDeletable == false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _displayNameController.text = e.displayName;
      _displayNameArController.text = e.displayNameAr ?? '';
      _placeholderController.text = e.placeholder ?? '';
      _validationRegexController.text = e.validationRegex ?? '';
      _dataType = e.dataType;
      _isRequired = e.isRequired;
      _isReadOnly = e.isReadOnly;
      _isHidden = e.isHidden;
      for (final o in e.options) {
        _options.add(
          _OptionControllers(
            id: o.id,
            value: TextEditingController(text: o.value),
            label: TextEditingController(text: o.displayText),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayNameArController.dispose();
    _placeholderController.dispose();
    _validationRegexController.dispose();
    for (final o in _options) {
      o.value.dispose();
      o.label.dispose();
    }
    super.dispose();
  }

  void _ensureDefaultPosition(List<CustomFieldDefinitionReadDto> sortedActive) {
    final positionCount = positionOptionCount(
      isCreate: !_isEdit,
      sortedActive: sortedActive,
    );

    if (_displayPosition == null) {
      if (_isEdit && widget.existing != null) {
        _displayPosition = clampFieldPosition(
          currentFieldPosition(widget.existing!, sortedActive),
          positionCount,
        );
      } else {
        _displayPosition = positionCount;
      }
      return;
    }

    _displayPosition = clampFieldPosition(_displayPosition!, positionCount);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defsQuery = (
      entityName: widget.entityName,
      includeInactive: true,
    );
    final defsAsync = ref.watch(customFieldDefinitionsProvider(defsQuery));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? (_isSystemField ? l10n.editSystemField : l10n.editCustomField)
              : l10n.newCustomField,
        ),
      ),
      body: defsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(customFieldDefinitionsProvider(defsQuery)),
        ),
        data: (defs) {
          final sortedActive = sortedActiveProvisionedFields(defs, l10n: l10n);
          _ensureDefaultPosition(sortedActive);
          final positionCount = positionOptionCount(
            isCreate: !_isEdit,
            sortedActive: sortedActive,
          );
          final selectedPosition = clampFieldPosition(
            _displayPosition ?? positionCount,
            positionCount,
          );
          if (_displayPosition != selectedPosition) {
            _displayPosition = selectedPosition;
          }

          final positionItems = <int, String>{};
          for (var index = 0; index < positionCount; index++) {
            final position = index + 1;
            positionItems[position] = fieldAppearancePositionLabel(
              l10n,
              position,
              total: positionCount,
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isSystemField)
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.systemFieldBadge,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.systemFieldKeyLockedLabel(
                              localizedFieldDisplayLabel(widget.existing!, l10n),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isSystemField) const SizedBox(height: 12),
                AppTextField(
                  controller: _displayNameController,
                  label: l10n.displayNameEnglishLabel,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? l10n.displayNameRequired
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _displayNameArController,
                  label: l10n.displayNameArabicLabel,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CustomFieldDataType>(
                  initialValue: _dataType,
                  decoration: InputDecoration(labelText: l10n.fieldTypeLabel),
                  items: CustomFieldDataType.values
                      .where((t) => t != CustomFieldDataType.unknown)
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(l10n.labelForDataType(t)),
                        ),
                      )
                      .toList(),
                  onChanged: (_isEdit || _isSystemField)
                      ? null
                      : (v) => setState(() => _dataType = v ?? _dataType),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedPosition,
                  decoration: InputDecoration(
                    labelText: l10n.fieldAppearancePositionLabel,
                  ),
                  items: positionItems.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _displayPosition = v),
                ),
                SwitchListTile(
                  title: Text(l10n.fieldRequiredLabel),
                  value: _isRequired,
                  onChanged: _isCriticalField
                      ? null
                      : (v) => setState(() => _isRequired = v),
                ),
                SwitchListTile(
                  title: Text(l10n.fieldReadOnlyLabel),
                  value: _isReadOnly,
                  onChanged: (_isCriticalField ||
                          (_isSystemField && widget.existing?.isReadOnly == true))
                      ? null
                      : (v) => setState(() => _isReadOnly = v),
                ),
                SwitchListTile(
                  title: Text(l10n.fieldHiddenLabel),
                  subtitle: Text(l10n.fieldHiddenHint),
                  value: _isHidden,
                  onChanged: _isCriticalField
                      ? null
                      : (v) => setState(() => _isHidden = v),
                ),
                AppTextField(
                  controller: _placeholderController,
                  label: l10n.placeholderLabel,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _validationRegexController,
                  label: l10n.validationRegexLabel,
                ),
                if (_dataType == CustomFieldDataType.singleSelect ||
                    _dataType == CustomFieldDataType.multiSelect) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.customFieldOptions,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ..._options.map(
                    (o) => Row(
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
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _options.add(
                        _OptionControllers(
                          value: TextEditingController(),
                          label: TextEditingController(),
                        ),
                      );
                    }),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addOption),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : () => _submit(sortedActive),
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
          );
        },
      ),
    );
  }

  Future<void> _submit(List<CustomFieldDefinitionReadDto> sortedActive) async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    if (_isEdit && widget.existing!.id <= 0) {
      showErrorSnackbar(context, l10n.systemFieldNotProvisioned);
      return;
    }

    final options = _buildOptions();
    if ((_dataType == CustomFieldDataType.singleSelect ||
            _dataType == CustomFieldDataType.multiSelect) &&
        (options == null || options.isEmpty)) {
      showErrorSnackbar(context, l10n.selectOptionsRequired);
      return;
    }

    final displayPosition = _displayPosition ??
        positionOptionCount(isCreate: !_isEdit, sortedActive: sortedActive);

    final displayNameAr = _displayNameArController.text.trim();

    setState(() => _loading = true);

    try {
      final repo = ref.read(customFieldRepositoryProvider);
      if (_isEdit) {
        await repo.updateDefinition(
          widget.existing!.id,
          CustomFieldDefinitionUpdateDto(
            displayName: _displayNameController.text.trim(),
            displayNameAr: displayNameAr.isEmpty ? '' : displayNameAr,
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            isHidden: _isHidden,
            displayPosition: displayPosition,
            placeholder: _placeholderController.text.trim().isEmpty
                ? ''
                : _placeholderController.text.trim(),
            validationRegex: _validationRegexController.text.trim().isEmpty
                ? ''
                : _validationRegexController.text.trim(),
            options: options,
          ),
        );
      } else {
        await repo.createDefinition(
          CustomFieldDefinitionCreateDto(
            displayName: _displayNameController.text.trim(),
            displayNameAr: displayNameAr.isEmpty ? null : displayNameAr,
            entityName: widget.entityName,
            dataType: customFieldDataTypeToApi(_dataType),
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            isHidden: _isHidden,
            displayPosition: displayPosition,
            placeholder: _placeholderController.text.trim().isEmpty
                ? null
                : _placeholderController.text.trim(),
            validationRegex: _validationRegexController.text.trim().isEmpty
                ? null
                : _validationRegexController.text.trim(),
            options: options,
          ),
        );
      }

      refreshEntityFormsAfterDefinitionChange(ref, widget.entityName);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
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
        .map(
          (o) => CustomFieldOptionDto(
            id: o.id,
            value: o.value.text.trim(),
            displayText: o.label.text.trim().isEmpty
                ? o.value.text.trim()
                : o.label.text.trim(),
          ),
        )
        .toList();
  }
}
