import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/utils/phone_number_validator.dart';

/// Opens the device native contact picker and returns a phone number only.
///
/// Flow (Android/iOS):
/// 1. Open the **permissionless** native contact picker (visible UI on tap).
/// 2. After a contact is chosen, request READ contacts permission.
/// 3. Load that contact's phone numbers and return one.
///
/// Contacts are never stored or uploaded — only the chosen number is returned.
abstract final class ContactPhonePicker {
  static Future<String?> pickPhoneNumber(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    if (!Platform.isAndroid && !Platform.isIOS) {
      if (context.mounted) {
        showErrorSnackbar(context, l10n.contactsPickerUnavailable);
      }
      return null;
    }

    try {
      // Permissionless on both platforms — system contacts UI opens first.
      final picked = await FlutterContacts.native.showPicker();
      if (picked == null) return null; // user cancelled
      if (!context.mounted) return null;

      final contactId = picked.id;
      if (contactId == null || contactId.isEmpty) {
        showErrorSnackbar(context, l10n.contactHasNoPhone);
        return null;
      }

      final permitted = await _ensureReadPermission(context, l10n);
      if (!permitted || !context.mounted) return null;

      final full = await FlutterContacts.get(
        contactId,
        properties: {ContactProperty.phone},
      );
      if (!context.mounted) return null;

      final phones = _usablePhones(full);
      if (phones.isEmpty) {
        showErrorSnackbar(context, l10n.contactHasNoPhone);
        return null;
      }

      final selected = phones.length == 1
          ? phones.first
          : await _choosePhone(context, l10n, phones);
      if (selected == null) return null;

      return _forFormField(selected);
    } on MissingPluginException catch (e, st) {
      debugPrint('ContactPhonePicker MissingPluginException: $e\n$st');
      if (context.mounted) {
        showErrorSnackbar(context, l10n.contactsPickerUnavailable);
      }
      return null;
    } on PlatformException catch (e, st) {
      debugPrint(
        'ContactPhonePicker PlatformException: ${e.code} ${e.message}\n$st',
      );
      if (context.mounted) {
        showErrorSnackbar(context, l10n.contactsPickerUnavailable);
      }
      return null;
    } catch (e, st) {
      debugPrint('ContactPhonePicker error: $e\n$st');
      if (context.mounted) {
        showErrorSnackbar(context, l10n.contactsPickerUnavailable);
      }
      return null;
    }
  }

  static Future<bool> _ensureReadPermission(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      // Already granted — avoid an unnecessary system prompt.
      if (await FlutterContacts.permissions.has(PermissionType.read)) {
        return true;
      }

      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );

      switch (status) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          return true;
        case PermissionStatus.permanentlyDenied:
        case PermissionStatus.restricted:
          if (context.mounted) {
            await _showOpenSettingsDialog(context, l10n);
          }
          return false;
        case PermissionStatus.denied:
        case PermissionStatus.notDetermined:
          if (context.mounted) {
            showErrorSnackbar(context, l10n.contactsPermissionDenied);
          }
          return false;
      }
    } on PlatformException catch (e, st) {
      debugPrint('Contacts permission request failed: ${e.message}\n$st');
      if (context.mounted) {
        // If the plugin cannot show the system prompt (e.g. missing activity
        // binding after a hot reload), guide the user to settings.
        await _showOpenSettingsDialog(context, l10n);
      }
      return false;
    }
  }

  static Future<void> _showOpenSettingsDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.selectFromContacts),
        content: Text(l10n.contactsPermissionPermanentlyDenied),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.openAppSettings),
          ),
        ],
      ),
    );
    if (open == true) {
      await FlutterContacts.permissions.openSettings();
    }
  }

  static List<Phone> _usablePhones(Contact? contact) {
    if (contact == null) return const [];
    return contact.phones
        .where((p) => p.number.trim().isNotEmpty)
        .toList(growable: false);
  }

  static Future<Phone?> _choosePhone(
    BuildContext context,
    AppLocalizations l10n,
    List<Phone> phones,
  ) {
    return showModalBottomSheet<Phone>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    l10n.selectContactPhoneNumber,
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: phones.length,
                    itemBuilder: (context, index) {
                      final phone = phones[index];
                      final label =
                          phone.label.customLabel?.trim().isNotEmpty == true
                          ? phone.label.customLabel!
                          : phone.label.label.name;
                      return ListTile(
                        leading: const Icon(Icons.phone_outlined),
                        title: Text(phone.number),
                        subtitle: Text(label),
                        onTap: () => Navigator.of(ctx).pop(phone),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _forFormField(Phone phone) {
    final raw = (phone.normalizedNumber?.trim().isNotEmpty == true)
        ? phone.normalizedNumber!.trim()
        : phone.number.trim();

    final normalized = PhoneNumberValidator.normalize(raw);
    if (normalized != null) return normalized;

    final cleaned = raw.replaceAll(RegExp(r'[^\d\s\-().+]'), '').trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }
}
