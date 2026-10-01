import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';

/// One-time setup and compact editor for church customization languages.
class CustomizationLanguagesSection extends ConsumerStatefulWidget {
  const CustomizationLanguagesSection({super.key});

  @override
  ConsumerState<CustomizationLanguagesSection> createState() =>
      _CustomizationLanguagesSectionState();
}

class _CustomizationLanguagesSectionState
    extends ConsumerState<CustomizationLanguagesSection> {
  bool _editing = false;
  bool? _otherLanguageUsed;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final churchAsync = ref.watch(churchLanguagesProvider);

    return churchAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: cw.AppErrorWidget(
            message: userFriendlyMessage(e, l10n),
            onRetry: () => ref.invalidate(churchLanguagesProvider),
          ),
        ),
      ),
      data: (church) {
        final showSetup = !church.isConfigured || _editing;
        return showSetup
            ? _SetupCard(
                church: church,
                editing: _editing,
                otherLanguageUsed: _otherLanguageUsed,
                saving: _saving,
                onOtherChanged: (value) =>
                    setState(() => _otherLanguageUsed = value),
                onCancel: church.isConfigured
                    ? () => setState(() {
                          _editing = false;
                          _otherLanguageUsed = null;
                        })
                    : null,
                onContinue: () => _save(church),
              )
            : _SummaryCard(
                church: church,
                onEdit: () => setState(() {
                      _editing = true;
                      _otherLanguageUsed = church.isBilingual;
                    }),
              );
      },
    );
  }

  Future<void> _save(ChurchLanguages current) async {
    final other = _otherLanguageUsed;
    if (other == null) {
      cw.showErrorSnackbar(
        context,
        AppLocalizations.of(context).customizationLanguagesAnswerRequired,
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final appLang = ref.read(localeProvider).languageCode ==
            OrganizationLanguages.arabic
        ? OrganizationLanguages.arabic
        : OrganizationLanguages.english;
    final otherLang = appLang == OrganizationLanguages.arabic
        ? OrganizationLanguages.english
        : OrganizationLanguages.arabic;

    final supported = <String>[appLang];
    if (other) supported.add(otherLang);

    final churchId = await ref.read(currentChurchIdProvider.future);
    if (churchId == null || churchId <= 0) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, l10n.customizationLanguagesSaveFailed);
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(languageSettingsRepositoryProvider).updateChurchLanguages(
            churchId: churchId,
            supportedLanguages: supported,
            defaultLanguage: appLang,
          );
      ref.invalidate(languageProfileProvider);
      ref.invalidate(churchLanguagesProvider);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _otherLanguageUsed = null;
        _saving = false;
      });
      cw.showSuccessSnackbar(context, l10n.changesSaved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.church, required this.onEdit});

  final ChurchLanguages church;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = <String>[
      if (church.supportsEnglish) l10n.english,
      if (church.supportsArabic) l10n.arabic,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.customizationLanguagesTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(onPressed: onEdit, child: Text(l10n.editLabel)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              labels.join(' + '),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.customizationLanguagesSummaryBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.church,
    required this.editing,
    required this.otherLanguageUsed,
    required this.saving,
    required this.onOtherChanged,
    required this.onContinue,
    this.onCancel,
  });

  final ChurchLanguages church;
  final bool editing;
  final bool? otherLanguageUsed;
  final bool saving;
  final ValueChanged<bool?> onOtherChanged;
  final VoidCallback onContinue;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final appIsArabic =
        Localizations.localeOf(context).languageCode == OrganizationLanguages.arabic;
    final yourLanguage =
        appIsArabic ? l10n.arabic : l10n.english;
    final otherLanguage =
        appIsArabic ? l10n.english : l10n.arabic;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.customizationLanguagesTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.customizationLanguagesSetupIntro),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.customizationLanguagesSetupPurpose,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.customizationLanguagesYourLanguage(yourLanguage),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.customizationLanguagesOtherQuestion(otherLanguage),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: true,
              groupValue: otherLanguageUsed,
              title: Text(l10n.yes),
              onChanged: saving ? null : onOtherChanged,
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              value: false,
              groupValue: otherLanguageUsed,
              title: Text(l10n.no),
              onChanged: saving ? null : onOtherChanged,
            ),
            if (otherLanguageUsed != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.customizationLanguagesPreviewTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('✓ $yourLanguage'),
              if (otherLanguageUsed == true) Text('✓ $otherLanguage'),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: saving ? null : onCancel,
                    child: Text(l10n.cancel),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: saving ? null : onContinue,
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          editing
                              ? l10n.saveLabel
                              : l10n.continueLabel,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
