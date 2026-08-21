import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Stable English weekday values stored in the API/database.
///
/// UI labels come from [AppLocalizations]; never send localized names to the API.
abstract final class WeekdayL10n {
  static const storageValues = <String>[
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  /// Maps a stored English/.NET weekday name to a localized label.
  static String label(AppLocalizations l10n, String? raw) {
    final key = raw?.trim();
    if (key == null || key.isEmpty) return l10n.notAvailable;

    switch (key.toLowerCase()) {
      case 'saturday':
        return l10n.weekdaySaturday;
      case 'sunday':
        return l10n.weekdaySunday;
      case 'monday':
        return l10n.weekdayMonday;
      case 'tuesday':
        return l10n.weekdayTuesday;
      case 'wednesday':
        return l10n.weekdayWednesday;
      case 'thursday':
        return l10n.weekdayThursday;
      case 'friday':
        return l10n.weekdayFriday;
      default:
        return key;
    }
  }

  /// Dropdown items: English [DropdownMenuItem.value], localized [child].
  static List<DropdownMenuItem<String>> dropdownItems(AppLocalizations l10n) {
    return [
      for (final value in storageValues)
        DropdownMenuItem(
          value: value,
          child: Text(label(l10n, value)),
        ),
    ];
  }
}
