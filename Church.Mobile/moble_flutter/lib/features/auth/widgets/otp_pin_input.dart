import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six single-digit fields for OTP entry.
class OtpPinInput extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const OtpPinInput({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<OtpPinInput> createState() => OtpPinInputState();
}

class OtpPinInputState extends State<OtpPinInput> {
  static const int length = 6;
  final _controllers = List.generate(length, (_) => TextEditingController());
  final _focusNodes = List.generate(length, (_) => FocusNode());

  String get value => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (mounted) _focusNodes.first.requestFocus();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String v) {
    if (v.length > 1) {
      _controllers[index].text = v.substring(v.length - 1);
    }
    if (v.isNotEmpty && index < length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    final code = value;
    widget.onChanged?.call(code);
    if (code.length == length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(length, (index) {
        return SizedBox(
          width: 44,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: widget.enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) => _onChanged(index, v),
            onSubmitted: (_) {
              if (index < length - 1) {
                _focusNodes[index + 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}
