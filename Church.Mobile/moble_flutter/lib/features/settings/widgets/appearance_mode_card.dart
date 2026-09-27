import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/theme_provider.dart';

/// Exposes the existing [themeModeProvider] Light / Dark / System control.
class AppearanceModeCard extends ConsumerWidget {
  const AppearanceModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final icon = switch (mode) {
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
    };

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(l10n.appearance),
            subtitle: Text(l10n.appearanceDescription),
          ),
          const Divider(height: 0),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: mode,
            title: Text(l10n.appearanceLight),
            onChanged: (value) => _setMode(ref, value),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: mode,
            title: Text(l10n.appearanceDark),
            onChanged: (value) => _setMode(ref, value),
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: mode,
            title: Text(l10n.appearanceSystem),
            onChanged: (value) => _setMode(ref, value),
          ),
        ],
      ),
    );
  }

  void _setMode(WidgetRef ref, ThemeMode? mode) {
    if (mode == null) return;
    ref.read(themeModeProvider.notifier).setThemeMode(mode);
  }
}
