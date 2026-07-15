import 'app_localizations.dart';

/// Maps English API / Identity validation text to [AppLocalizations] strings.
///
/// Backend messages stay English for stable contracts; the UI translates them
/// before display so Arabic and English never mix in the form.
class ValidationMessageLocalizer {
  ValidationMessageLocalizer._();

  static String localize(
    AppLocalizations l10n,
    String rawMessage, {
    String? apiFieldKey,
  }) {
    final fromCode = _fromIdentityOrFieldCode(l10n, apiFieldKey);
    if (fromCode != null) return fromCode;

    final normalized = _normalize(rawMessage);
    if (normalized.isEmpty) return l10n.validationFailed;

    final exact = _exactMessageMap(l10n)[normalized];
    if (exact != null) return exact;

    return _fuzzyMatch(l10n, normalized) ?? rawMessage.trim();
  }

  static List<String> localizeAll(
    AppLocalizations l10n,
    Iterable<String> messages, {
    String? apiFieldKey,
  }) {
    return messages
        .map((m) => localize(l10n, m, apiFieldKey: apiFieldKey))
        .toList(growable: false);
  }

  static Map<String, List<String>> localizeFieldErrors(
    AppLocalizations l10n,
    Map<String, List<String>> fieldErrors,
  ) {
    final result = <String, List<String>>{};
    fieldErrors.forEach((key, messages) {
      result[key] = localizeAll(l10n, messages, apiFieldKey: key);
    });
    return result;
  }

  static String? _fromIdentityOrFieldCode(
    AppLocalizations l10n,
    String? apiFieldKey,
  ) {
    if (apiFieldKey == null || apiFieldKey.isEmpty) return null;
    switch (apiFieldKey.trim().toLowerCase()) {
      case 'passwordtooshort':
        return l10n.passwordTooShort;
      case 'passwordrequiresdigit':
        return l10n.passwordRequiresDigit;
      case 'passwordrequireslowercase':
      case 'passwordrequireslower':
        return l10n.passwordRequiresLower;
      case 'passwordrequiresuppercase':
      case 'passwordrequiresupper':
        return l10n.passwordRequiresUpper;
      case 'passwordrequiresnonalphanumeric':
        return l10n.passwordRequiresNonAlphanumeric;
      default:
        return null;
    }
  }

  static Map<String, String> _exactMessageMap(AppLocalizations l10n) => {
        'name is required': l10n.nameRequired,
        'phone number is required': l10n.phoneRequired,
        'please enter valid phone number': l10n.phoneRequired,
        'password is required': l10n.passwordRequired,
        'confirm password is required': l10n.confirmPasswordRequired,
        'password and confirm password do not match': l10n.passwordsDoNotMatch,
        'passwords do not match': l10n.passwordsDoNotMatch,
        'passwords miss match': l10n.passwordsDoNotMatch,
        'passwords miss match.': l10n.passwordsDoNotMatch,
        'church name is required': l10n.churchNameRequired,
        'meeting name is required': l10n.meetingNameRequired,
        'weekly appointment is required': l10n.weeklyAppointmentRequired,
        'a church with this name already exists': l10n.churchNameAlreadyExists,
        'church already exists': l10n.churchAlreadyExists,
        'a valid church or meeting identifier is required':
            l10n.churchOrMeetingIdInvalid,
        'church id or meeting id is required': l10n.churchOrMeetingIdRequired,
        'requested meeting name is required': l10n.requestedMeetingNameRequired,
        'meeting admin phone number is required':
            l10n.meetingAdminPhoneRequired,
        'meeting admin phone number is required for servants':
            l10n.meetingAdminPhoneRequiredForServants,
        'church or meeting not found': l10n.churchOrMeetingNotFound,
        'phone number is invalid': l10n.phoneInvalid,
        'phone number already exists': l10n.phoneAlreadyUsed,
        'this phone number is already in use. please sign in or use a different number':
            l10n.phoneAlreadyUsed,
        'registration failed due to a username conflict. please try again':
            l10n.registrationUsernameConflict,
        'the selected meeting does not belong to the selected church':
            l10n.meetingNotInChurch,
        'validation failed': l10n.validationFailed,
        'validation error': l10n.validationFailed,
        'one or more validation errors occurred': l10n.validationFailed,
        'one or more fields failed model binding or validation':
            l10n.validationFailed,
        'registration data cannot be null': l10n.registrationDataInvalid,
        'password must contain at least 6 characters':
            l10n.passwordMustContainAtLeast6,
        'password must be at least 6 characters': l10n.passwordTooShort,
        'passwords must match': l10n.passwordsDoNotMatch,
      };

  static String? _fuzzyMatch(AppLocalizations l10n, String normalized) {
    if (normalized.contains('phone') &&
        (normalized.contains('already') ||
            normalized.contains('exist') ||
            normalized.contains('duplicate') ||
            normalized.contains('taken'))) {
      return l10n.phoneAlreadyUsed;
    }
    if (normalized.contains('phone') && normalized.contains('invalid')) {
      return l10n.phoneInvalid;
    }
    if (normalized.contains('password') &&
        normalized.contains('confirm') &&
        (normalized.contains('match') || normalized.contains('miss'))) {
      return l10n.passwordsDoNotMatch;
    }
    if (normalized.contains('password') &&
        (normalized.contains('6') || normalized.contains('short'))) {
      return l10n.passwordTooShort;
    }
    if (normalized.contains('digit')) return l10n.passwordRequiresDigit;
    if (normalized.contains('lowercase')) return l10n.passwordRequiresLower;
    if (normalized.contains('uppercase')) return l10n.passwordRequiresUpper;
    if (normalized.contains('non-alphanumeric') ||
        normalized.contains('nonalphanumeric')) {
      return l10n.passwordRequiresNonAlphanumeric;
    }
    if (normalized.contains('church or meeting not found') ||
        (normalized.contains('not found') &&
            (normalized.contains('church') || normalized.contains('meeting')))) {
      return l10n.churchOrMeetingNotFound;
    }
    if (normalized.contains('weekly appointment')) {
      return l10n.weeklyAppointmentRequired;
    }
    if (normalized.contains('requested meeting')) {
      return l10n.requestedMeetingNameRequired;
    }
    if (normalized.contains('meeting admin phone')) {
      return l10n.meetingAdminPhoneRequiredForServants;
    }
    if (normalized.contains('username conflict')) {
      return l10n.registrationUsernameConflict;
    }
    return null;
  }

  static String _normalize(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[.!\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
