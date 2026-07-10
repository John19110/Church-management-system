import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

/// Locale-aware number, date, and digit formatting for UI display.
abstract final class LocaleFormat {
  static const _westernDigits = '0123456789';
  static const _easternArabicDigits = '٠١٢٣٤٥٦٧٨٩';

  static bool usesEasternArabicDigits(Locale locale) =>
      locale.languageCode == 'ar';

  static TextDirection textDirectionFor(Locale locale) =>
      usesEasternArabicDigits(locale) ? TextDirection.rtl : TextDirection.ltr;

  static TextAlign textAlignFor(Locale locale) =>
      usesEasternArabicDigits(locale) ? TextAlign.right : TextAlign.start;

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

  /// Converts Western digits in free text (e.g. age ranges "5-7").
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

  /// Parses API/storage values (`yyyy-MM-dd`, ISO-8601).
  static DateTime? tryParseStoredDate(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;

    final datePart = trimmed.split('T').first;
    final parts = datePart.split('-');
    if (parts.length >= 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Locale-aware short date for display (not storage).
  static String dateYmd(DateTime date, Locale locale) {
    final formatted =
        DateFormat.yMd(locale.languageCode).format(_dateOnly(date));
    return usesEasternArabicDigits(locale)
        ? digitsIn(formatted, locale)
        : formatted;
  }

  /// Formats a stored date string for UI preview/detail rows.
  static String formatDateString(String? raw, Locale locale) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';

    final parsed = tryParseStoredDate(trimmed);
    if (parsed == null) return digitsIn(trimmed, locale);
    return dateYmd(parsed, locale);
  }

  /// Formats a stored date-time string for UI preview/detail rows.
  static String formatDateTimeString(String? raw, Locale locale) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';

    final parsed = tryParseStoredDate(trimmed);
    if (parsed == null) return digitsIn(trimmed, locale);

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final formatted = DateFormat.yMd(locale.languageCode)
        .add_jm()
        .format(local);
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
