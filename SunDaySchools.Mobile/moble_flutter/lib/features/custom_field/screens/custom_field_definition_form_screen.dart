import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/custom_field_models.dart';
import '../providers/custom_field_providers.dart';
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
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  CustomFieldDataType _dataType = CustomFieldDataType.text;
  bool _isRequired = false;
  bool _isReadOnly = false;
  bool _isHidden = false;
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
      _descriptionController.text = e.description ?? '';
      _dataType = e.dataType;
      _isRequired = e.isRequired;
      _isReadOnly = e.isReadOnly;
      _isHidden = e.isHidden;
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
    _nameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    for (final o in _options) {
      o.value.dispose();
      o.label.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit custom field' : 'New custom field'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEdit)
              AppTextField(
                controller: _nameController,
                label: 'Internal name',
                hint: 'e.g. baptism_date',
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(v.trim())) {
                    return 'Letters, numbers, underscore only';
                  }
                  return null;
                },
              ),
            AppTextField(
              controller: _displayNameController,
              label: 'Display name',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CustomFieldDataType>(
              value: _dataType,
              decoration: const InputDecoration(labelText: 'Field type'),
              items: CustomFieldDataType.values
                  .where((t) => t != CustomFieldDataType.unknown)
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name),
                      ))
                  .toList(),
              onChanged: _isEdit
                  ? null
                  : (v) => setState(() => _dataType = v ?? _dataType),
            ),
            SwitchListTile(
              title: const Text('Required'),
              value: _isRequired,
              onChanged: (v) => setState(() => _isRequired = v),
            ),
            SwitchListTile(
              title: const Text('Read only'),
              value: _isReadOnly,
              onChanged: (v) => setState(() => _isReadOnly = v),
            ),
            SwitchListTile(
              title: const Text('Hidden'),
              value: _isHidden,
              onChanged: (v) => setState(() => _isHidden = v),
            ),
            if (_dataType == CustomFieldDataType.singleSelect ||
                _dataType == CustomFieldDataType.multiSelect) ...[
              const SizedBox(height: 8),
              Text('Options', style: Theme.of(context).textTheme.titleSmall),
              ..._options.map((o) => Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: o.value,
                          label: 'Value',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppTextField(
                          controller: o.label,
                          label: 'Label',
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
                label: const Text('Add option'),
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
                  : Text(_isEdit ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(customFieldRepositoryProvider);
      if (_isEdit) {
        final options = _buildOptions();
        await repo.updateDefinition(
          widget.existing!.id,
          CustomFieldDefinitionUpdateDto(
            displayName: _displayNameController.text.trim(),
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            isHidden: _isHidden,
            options: options,
          ),
        );
      } else {
        await repo.createDefinition(
          CustomFieldDefinitionCreateDto(
            name: _nameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            entityName: widget.entityName,
            dataType: customFieldDataTypeToApi(_dataType),
            isRequired: _isRequired,
            isReadOnly: _isReadOnly,
            isHidden: _isHidden,
            options: _buildOptions(),
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
