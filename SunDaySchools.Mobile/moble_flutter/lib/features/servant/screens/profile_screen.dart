import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/utils/auth_role_utils.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../providers/servants_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(servantProfileProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
    final isSuperAdmin = role == 'superadmin';
    final homeRoute = AuthRoleUtils.routeForRole(role);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(l10n.profile)) : null,
      bottomNavigationBar: AppSectionBottomNavigationBar(
        currentIndex: 3,
        homeRoute: homeRoute,
      ),
      body: profileAsync.when(
        loading: () => const cw.LoadingWidget(),
        error: (e, _) => cw.AppErrorWidget(
          message: userFriendlyMessage(e, l10n),
          onRetry: () => ref.invalidate(servantProfileProvider),
        ),
        data: (profile) {
          if (profile.id <= 0) {
            return cw.AppErrorWidget(message: l10n.failedToLoadProfile);
          }

          final formAsync = ref.watch(
            entityFormDataProvider((
              entity: UnifiedEntityNames.servant,
              id: profile.id,
            )),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servantProfileProvider);
              ref.invalidate(
                entityFormDataProvider((
                  entity: UnifiedEntityNames.servant,
                  id: profile.id,
                )),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                formAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => cw.AppErrorWidget(
                    message: userFriendlyMessage(e, l10n),
                    onRetry: () => ref.invalidate(
                      entityFormDataProvider((
                        entity: UnifiedEntityNames.servant,
                        id: profile.id,
                      )),
                    ),
                  ),
                  data: (formData) => Column(
                    children: [
                      UnifiedEntityDetailHeader(
                        entityName: UnifiedEntityNames.servant,
                        fields: formData.fields,
                        avatarRadius: 56,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.profileInformation,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (formData.fields.isEmpty)
                        EntityFieldsEmptyState(
                          entityName: UnifiedEntityNames.servant,
                          canManageDefinitions: false,
                        )
                      else
                        UnifiedEntityDetailFields(
                          fields: formData.fields,
                          entityName: UnifiedEntityNames.servant,
                        ),
                    ],
                  ),
                ),
                if (isSuperAdmin) ...[
                  const SizedBox(height: 16),
                  const _SuperAdminChurchIdCard(),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.appSettings,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                        ),
                        title: Text(isDark ? l10n.darkMode : l10n.lightMode),
                        value: isDark,
                        onChanged: (_) =>
                            ref.read(themeModeProvider.notifier).toggle(),
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.language),
                        subtitle: Text(isArabic ? l10n.arabic : l10n.english),
                        trailing: TextButton(
                          onPressed: () =>
                              ref.read(localeProvider.notifier).toggle(),
                          child: Text(isArabic ? l10n.english : l10n.arabic),
                        ),
                        onTap: () => ref.read(localeProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    await context.push(AppRoutes.profileEdit);
                    ref.invalidate(servantProfileProvider);
                    ref.invalidate(
                      entityFormDataProvider((
                        entity: UnifiedEntityNames.servant,
                        id: profile.id,
                      )),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(l10n.editProfile),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SuperAdminChurchIdCard extends ConsumerWidget {
  const _SuperAdminChurchIdCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(servantProfileProvider);

    return profileAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        final churchPublicId = profile.church?.publicId ?? '';
        if (churchPublicId.isEmpty) {
          return const SizedBox.shrink();
        }

        final churchIdText = churchPublicId;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.church_outlined),
            title: Text(l10n.churchIdLabel),
            subtitle: SelectableText(
              churchIdText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              tooltip: l10n.copyLabel,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: churchIdText));
                cw.showSuccessSnackbar(context, l10n.churchIdCopied);
              },
            ),
          ),
        );
      },
    );
  }
}
