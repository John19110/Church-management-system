import 'package:flutter/material.dart';

import '../../core/l10n/locale_format.dart';

/// Date preview text with locale-aware formatting and reading direction.
class LocaleDateText extends StatelessWidget {
  final String? value;
  final DateTime? dateTime;
  final Locale locale;
  final bool includeTime;
  final TextStyle? style;
  final String? emptyText;

  const LocaleDateText({
    super.key,
    this.value,
    this.dateTime,
    required this.locale,
    this.includeTime = false,
    this.style,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final display = _displayText();
    return Text(
      display,
      style: style,
      textDirection: LocaleFormat.textDirectionFor(locale),
      textAlign: LocaleFormat.textAlignFor(locale),
    );
  }

  String _displayText() {
    if (dateTime != null) {
      return includeTime
          ? LocaleFormat.formatDateTimeString(dateTime!.toIso8601String(), locale)
          : LocaleFormat.dateYmd(dateTime!, locale);
    }

    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return emptyText ?? '';
    }

    return includeTime
        ? LocaleFormat.formatDateTimeString(raw, locale)
        : LocaleFormat.formatDateString(raw, locale);
  }
}
