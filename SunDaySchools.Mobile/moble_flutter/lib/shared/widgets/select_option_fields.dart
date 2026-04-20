import 'package:flutter/material.dart';

import '../../core/models/select_option.dart';

class SelectOptionDropdown extends StatelessWidget {
  final String label;
  final List<SelectOption> options;
  final int? value;
  final String? hintText;
  final bool enabled;
  final void Function(int?) onChanged;
  final String? Function(int?)? validator;

  const SelectOptionDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
      ),
      items: options
          .map(
            (o) => DropdownMenuItem<int>(
              value: o.id,
              child: Text(o.name.isEmpty ? '#${o.id}' : o.name),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      validator: validator,
    );
  }
}

class SelectOptionMultiSelectField extends StatefulWidget {
  final String label;
  final List<SelectOption> options;
  final List<int> selectedIds;
  final void Function(List<int>) onChanged;
  final String? hintText;

  const SelectOptionMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<SelectOptionMultiSelectField> createState() =>
      _SelectOptionMultiSelectFieldState();
}

class _SelectOptionMultiSelectFieldState extends State<SelectOptionMultiSelectField> {
  Future<void> _openPicker() async {
    final current = widget.selectedIds.toSet();
    final selected = await showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final temp = current.toSet();
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(temp),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: widget.options.map((o) {
                          final isChecked = temp.contains(o.id);
                          return CheckboxListTile(
                            value: isChecked,
                            title: Text(o.name.isEmpty ? '#${o.id}' : o.name),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  temp.add(o.id);
                                } else {
                                  temp.remove(o.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return;
    widget.onChanged(selected.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
    final selectedNames = widget.options
        .where((o) => widget.selectedIds.contains(o.id))
        .map((o) => o.name.isEmpty ? '#${o.id}' : o.name)
        .toList();

    final text = selectedNames.isEmpty
        ? (widget.hintText ?? 'Select')
        : selectedNames.join(', ');

    return InkWell(
      onTap: _openPicker,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          text,
          style: selectedNames.isEmpty
              ? TextStyle(color: Theme.of(context).hintColor)
              : null,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

