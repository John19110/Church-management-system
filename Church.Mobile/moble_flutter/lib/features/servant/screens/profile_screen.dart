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
import '../../auth/widgets/delete_account_section.dart';
import '../../../shared/widgets/common_widgets.dart' as cw;
import '../../../shared/widgets/app_section_bottom_navigation_bar.dart';
import '../../unified_form/models/unified_form_models.dart';
import '../../unified_form/providers/unified_form_providers.dart';
import '../../unified_form/widgets/entity_fields_empty_state.dart';
import '../../unified_form/widgets/unified_entity_detail_header.dart';
import '../../unified_form/widgets/unified_entity_form.dart';
import '../models/servant_models.dart';
import '../providers/servants_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(servantProfileProvider);
    final role = ref.watch(currentUserRoleProvider).resolvedRoleOrNull;
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

          final formAsync = ref.watch(servantProfileFormDataProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(servantProfileProvider);
              ref.invalidate(servantProfileFormDataProvider);
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
                  loading: () => Column(
                    children: [
                      UnifiedEntityDetailHeader(
                        entityName: UnifiedEntityNames.servant,
                        fields: const [],
                        imageUrl: profile.displayImageUrl,
                        avatarRadius: 56,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                  error: (e, _) => Column(
                    children: [
                      UnifiedEntityDetailHeader(
                        entityName: UnifiedEntityNames.servant,
                        fields: const [],
                        imageUrl: profile.displayImageUrl,
                        avatarRadius: 56,
                      ),
                      cw.AppErrorWidget(
                        message: userFriendlyMessage(e, l10n),
                        onRetry: () =>
                            ref.invalidate(servantProfileFormDataProvider),
                      ),
                    ],
                  ),
                  data: (formData) => Column(
                    children: [
                      UnifiedEntityDetailHeader(
                        entityName: UnifiedEntityNames.servant,
                        fields: formData.fields,
                        imageUrl: profile.displayImageUrl,
                        avatarRadius: 56,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.profileInformation,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (formData.fields.isEmpty)
                        const EntityFieldsEmptyState(
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
                const SizedBox(height: 16),
                _RoleContextCard(profile: profile, role: role),
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
                    ref.invalidate(servantProfileFormDataProvider);
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
                const SizedBox(height: 20),
                const DeleteAccountSection(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Account role and church / meeting assignment based on the signed-in user.
class _RoleContextCard extends StatelessWidget {
  const _RoleContextCard({required this.profile, required this.role});

  final ServantProfileDto profile;
  final String? role;

  static String _roleLabel(AppLocalizations l10n, String? role) {
    switch (role) {
      case 'superadmin':
        return l10n.registerTypeChurchAdmin;
      case 'admin':
        return l10n.registerTypeMeetingAdmin;
      case 'servant':
        return l10n.registerTypeServant;
      default:
        return l10n.notAvailable;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSuperAdmin = role == 'superadmin';
    final showMeeting = role == 'admin' || role == 'servant';
    final showChurchContext =
        isSuperAdmin || role == 'admin' || role == 'servant';

    final churchName = profile.church?.name?.trim() ?? '';
    final churchPublicId = profile.church?.publicId.trim() ?? '';
    final meetingPublicId = profile.meeting?.publicId.trim() ?? '';
    final meetingName = profile.meeting?.name?.trim() ?? '';

    final churchDisplay = churchName.isNotEmpty
        ? churchName
        : l10n.notAvailable;
    final meetingDisplay = meetingName.isNotEmpty
        ? meetingName
        : l10n.notAvailable;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: Text(l10n.requestedRoleLabel),
            subtitle: Text(
              _roleLabel(l10n, role),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (showChurchContext) ...[
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.church_outlined),
              title: Text(l10n.churchName),
              subtitle: Text(
                churchDisplay,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (isSuperAdmin && churchPublicId.isNotEmpty) ...[
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.tag_outlined),
              title: Text(l10n.churchIdLabel),
              subtitle: SelectableText(
                churchPublicId,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.copyLabel,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: churchPublicId));
                  cw.showSuccessSnackbar(context, l10n.churchIdCopied);
                },
              ),
            ),
          ],
          if (showMeeting) ...[
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n.meetingName),
              subtitle: Text(
                meetingDisplay,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (role == 'admin' && meetingPublicId.isNotEmpty) ...[
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.tag_outlined),
              title: Text(l10n.meetingIdLabel),
              subtitle: SelectableText(
                meetingPublicId,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.copyLabel,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: meetingPublicId));
                  cw.showSuccessSnackbar(context, l10n.meetingIdCopied);
                },
              ),
            ),
          ],
          if (isSuperAdmin && profile.churchMeetings.isNotEmpty) ...[
            const Divider(height: 0),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.churchMeetingsIdsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ...profile.churchMeetings.map((m) {
              final id = m.publicId.trim();
              final name = (m.name?.trim().isNotEmpty == true)
                  ? m.name!.trim()
                  : l10n.meetingLabel;
              return ListTile(
                dense: true,
                title: Text(name),
                subtitle: id.isNotEmpty ? SelectableText(id) : null,
                trailing: id.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: l10n.copyLabel,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: id));
                          cw.showSuccessSnackbar(context, l10n.meetingIdCopied);
                        },
                      ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
