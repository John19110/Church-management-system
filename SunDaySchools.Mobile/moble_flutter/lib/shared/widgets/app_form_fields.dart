import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// Styled text field for forms.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: obscureText ? 1 : maxLines,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// A date picker form field (stores ISO yyyy-MM-dd; displays locale digits).
class AppDateField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  const AppDateField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  @override
  State<AppDateField> createState() => _AppDateFieldState();
}

class _AppDateFieldState extends State<AppDateField> {
  late final TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController();
    widget.controller.addListener(_syncDisplay);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDisplay();
  }

  @override
  void didUpdateWidget(covariant AppDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncDisplay);
      widget.controller.addListener(_syncDisplay);
      _syncDisplay();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncDisplay);
    _displayController.dispose();
    super.dispose();
  }

  String _displayText() {
    final raw = widget.controller.text.trim();
    if (raw.isEmpty) return '';
    final l10n = AppLocalizations.of(context);
    return l10n.formatDigitsIn(raw);
  }

  void _syncDisplay() {
    final next = _displayText();
    if (_displayController.text != next) {
      _displayController.text = next;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _displayController,
      readOnly: true,
      validator: (_) => widget.validator?.call(widget.controller.text),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.tryParse(widget.controller.text) ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          widget.controller.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          _syncDisplay();
        }
      },
    );
  }
}
