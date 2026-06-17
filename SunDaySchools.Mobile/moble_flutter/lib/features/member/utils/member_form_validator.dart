import '../../../core/l10n/app_localizations.dart';
import 'member_form_controller.dart';

abstract final class MemberFormValidator {
  static final _phonePattern = RegExp(r'^\+?[\d\s\-()]{7,20}$');

  static String? validateFirstName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.firstNameRequired;
    }
    return null;
  }

  static String? validatePhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!_phonePattern.hasMatch(trimmed)) {
      return l10n.invalidPhoneFormat;
    }
    return null;
  }

  static String? validateRelation(String? relation, String? phone, AppLocalizations l10n) {
    final phoneTrimmed = phone?.trim() ?? '';
    if (phoneTrimmed.isEmpty) return null;
    if (relation == null || relation.trim().isEmpty) {
      return l10n.relationRequiredWhenPhone;
    }
    return null;
  }

  static bool validateForm(
    MemberFormController form,
    AppLocalizations l10n,
  ) {
    if (validateFirstName(form.name1Controller.text, l10n) != null) {
      return false;
    }
    for (final entry in form.phones) {
      if (validatePhone(entry.phoneController.text, l10n) != null) {
        return false;
      }
      if (validateRelation(
            entry.relation,
            entry.phoneController.text,
            l10n,
          ) !=
          null) {
        return false;
      }
    }
    return true;
  }
}
