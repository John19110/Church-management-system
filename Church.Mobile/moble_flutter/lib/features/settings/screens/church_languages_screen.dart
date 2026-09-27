import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/organization_languages.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../models/language_settings.dart';
import '../providers/language_settings_providers.dart';

class ChurchLanguagesScreen extends ConsumerStatefulWidget {
  const ChurchLanguagesScreen({super.key});

  @override
  ConsumerState<ChurchLanguagesScreen> createState() =>
      _ChurchLanguagesScreenState();
}

class _ChurchLanguagesScreenState extends ConsumerState<ChurchLanguagesScreen> {
  bool? _english;
  bool? _arabic;
  String? _defaultLanguage;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final churchIdAsync = ref.watch(currentChurchIdProvider);
    if (!AuthRoleUtils.canManageCustomFields(role)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.churchLanguages)),
        body: Center(child: Text(l10n.notAuthorized)),
      );
    }

    final languagesAsync = ref.watch(churchLanguagesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.churchLanguages)),
      body: languagesAsync.when(
        loading: () => const cw.LoadingWidget(useSkeleton: true),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(churchLanguagesProvider),
        ),
        data: (church) {
          _english ??= church.supportsEnglish;
          _arabic ??= church.supportsArabic;
          _defaultLanguage ??= church.defaultLanguage;
          final english = _english!;
          final arabic = _arabic!;
          var defaultLanguage = _defaultLanguage!;
          if (defaultLanguage == OrganizationLanguages.english && !english) {
            defaultLanguage = OrganizationLanguages.arabic;
          }
          if (defaultLanguage == OrganizationLanguages.arabic && !arabic) {
            defaultLanguage = OrganizationLanguages.english;
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(l10n.churchLanguagesDescription),
              const SizedBox(height: AppSpacing.md),
              CheckboxListTile(
                value: english,
                title: Text(l10n.english),
                onChanged: (value) {
                  if (value == false && !arabic) return;
                  setState(() => _english = value ?? true);
                },
              ),
              CheckboxListTile(
                value: arabic,
                title: Text(l10n.arabic),
                onChanged: (value) {
                  if (value == false && !english) return;
                  setState(() => _arabic = value ?? true);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: defaultLanguage,
                decoration: InputDecoration(labelText: l10n.defaultLanguage),
                items: [
                  if (english)
                    DropdownMenuItem(
                      value: OrganizationLanguages.english,
                      child: Text(l10n.english),
                    ),
                  if (arabic)
                    DropdownMenuItem(
                      value: OrganizationLanguages.arabic,
                      child: Text(l10n.arabic),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _defaultLanguage = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.usersChoosePreferredLanguage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _saving
                    ? null
                    : () => _save(
                          church,
                          churchId: churchIdAsync.valueOrNull,
                          english: english,
                          arabic: arabic,
                          defaultLanguage: defaultLanguage,
                        ),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(
    ChurchLanguages current, {
    required int? churchId,
    required bool english,
    required bool arabic,
    required String defaultLanguage,
  }) async {
    if (churchId == null || churchId <= 0) return;
    final l10n = AppLocalizations.of(context);
    final removingArabic = current.supportsArabic && !arabic;
    final removingEnglish = current.supportsEnglish && !english;
    if (removingArabic || removingEnglish) {
      final label = removingArabic ? l10n.arabic : l10n.english;
      final ok = await cw.showConfirmDialog(
        context,
        title: l10n.removeLanguageTitle(label),
        content: l10n.removeLanguageBody(label),
        confirmText: l10n.removeLanguageConfirm(label),
      );
      if (!ok) return;
    }

    final supported = <String>[
      if (english) OrganizationLanguages.english,
      if (arabic) OrganizationLanguages.arabic,
    ];
    setState(() => _saving = true);
    try {
      await ref.read(languageSettingsRepositoryProvider).updateChurchLanguages(
            churchId: churchId,
            supportedLanguages: supported,
            defaultLanguage: defaultLanguage,
          );
      ref.invalidate(languageProfileProvider);
      if (!mounted) return;
      cw.showSuccessSnackbar(context, l10n.changesSaved);
    } catch (e) {
      if (!mounted) return;
      cw.showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
