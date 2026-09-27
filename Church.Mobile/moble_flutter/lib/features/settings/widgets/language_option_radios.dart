import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';

class LanguageOptionRadios extends StatelessWidget {
  const LanguageOptionRadios({
    super.key,
    required this.groupValue,
    required this.supportedLanguages,
    required this.onChanged,
  });

  final String groupValue;
  final List<String> supportedLanguages;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        for (final code in supportedLanguages)
          RadioListTile<String>(
            value: code,
            groupValue: groupValue,
            title: Text(
              code == OrganizationLanguages.arabic ? l10n.arabic : l10n.english,
            ),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
      ],
    );
  }
}
