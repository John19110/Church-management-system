import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Locale-aware number and digit formatting for UI display.
abstract final class LocaleFormat {
  static const _westernDigits = '0123456789';
  static const _easternArabicDigits = '٠١٢٣٤٥٦٧٨٩';

  static bool usesEasternArabicDigits(Locale locale) =>
      locale.languageCode == 'ar';

  /// Formats integers/decimals using the active locale (Arabic → ٠١٢٣…).
  ///
  /// Dart's [NumberFormat] for `ar` often still emits Western digits (0–9);
  /// we map those to Eastern Arabic numerals when the UI locale is Arabic.
  static String number(num value, Locale locale) {
    final formatted =
        NumberFormat.decimalPattern(locale.languageCode).format(value);
    return usesEasternArabicDigits(locale) ? digitsIn(formatted, locale) : formatted;
  }

  static String integer(int value, Locale locale) =>
      number(value, locale);

  /// Converts Western digits in free text (e.g. age ranges "5-7", dates).
  static String digitsIn(String text, Locale locale) {
    if (!usesEasternArabicDigits(locale) || text.isEmpty) return text;

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final index = _westernDigits.indexOf(char);
      buffer.write(
        index >= 0 ? _easternArabicDigits[index] : char,
      );
    }
    return buffer.toString();
  }

  /// ISO date string for form storage; display digits follow locale.
  static String dateYmd(DateTime date, Locale locale) {
    final formatted = DateFormat.yMd(locale.languageCode).format(date);
    return usesEasternArabicDigits(locale)
        ? digitsIn(formatted, locale)
        : formatted;
  }

  /// Parses numeric strings and formats with locale; otherwise localizes digits only.
  static String formatNumericString(String raw, Locale locale) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    final parsed = num.tryParse(trimmed.replaceAll(',', ''));
    if (parsed != null) {
      return number(parsed, locale);
    }

    return digitsIn(trimmed, locale);
  }
}
