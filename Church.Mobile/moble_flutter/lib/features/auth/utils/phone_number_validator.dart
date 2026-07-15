import '../../../core/l10n/app_localizations.dart';

/// Client-side phone validation aligned with backend [PhoneNumberNormalizer].
class PhoneNumberValidator {
  PhoneNumberValidator._();

  static final RegExp _allowedChars = RegExp(r'^[\d\s\-().+]+$');
  static final RegExp _nonDigits = RegExp(r'\D');

  /// Returns a localized error message, or null when valid.
  static String? validate(
    String? raw, {
    required AppLocalizations l10n,
    bool required = true,
  }) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return required ? l10n.phoneRequired : null;
    }

    if (!_allowedChars.hasMatch(value)) {
      return l10n.phoneInvalid;
    }

    final plusCount = '+'.allMatches(value).length;
    if (plusCount > 1 || (plusCount == 1 && !value.startsWith('+'))) {
      return l10n.phoneInvalid;
    }

    if (normalize(value) == null) {
      return l10n.phoneInvalid;
    }
    return null;
  }

  /// Digits with country code (default Egypt 20), matching backend storage.
  static String? normalize(String? raw, {String defaultCountryCode = '20'}) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (!_allowedChars.hasMatch(trimmed)) return null;

    final plusCount = '+'.allMatches(trimmed).length;
    if (plusCount > 1 || (plusCount == 1 && !trimmed.startsWith('+'))) {
      return null;
    }

    var digits = trimmed.replaceAll(_nonDigits, '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('0') && digits.length > 1) {
      digits = '$defaultCountryCode${digits.substring(1)}';
    } else if (!digits.startsWith(defaultCountryCode) && digits.length <= 11) {
      digits = '$defaultCountryCode$digits';
    }

    if (digits.length < 10 || digits.length > 15) return null;

    if (defaultCountryCode == '20' && digits.startsWith('20')) {
      final national = digits.substring(2);
      if (national.length != 10 || !national.startsWith('1')) return null;
    }

    return digits;
  }
}
