import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../utils/registration_navigation.dart';
import '../widgets/registration_choice_card.dart';

/// Flow 2 (church does not exist yet): choose which administrator to register as.
/// Both options reuse the existing registration forms.
class NewChurchRoleScreen extends StatelessWidget {
  const NewChurchRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return registrationBackScope(
      context: context,
      fallbackRoute: AppRoutes.register,
      child: Scaffold(
        appBar: registrationAppBar(
          context: context,
          title: l10n.createAccount,
          fallbackRoute: AppRoutes.register,
        ),
        body: SafeArea(
          child: AppFormScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.selectRegistrationType,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                RegistrationChoiceCard(
                  icon: Icons.groups_outlined,
                  title: l10n.registerTypeMeetingAdmin,
                  onTap: () =>
                      context.push(AppRoutes.registerNewChurchMeetingAdmin),
                ),
                const SizedBox(height: AppSpacing.md),
                RegistrationChoiceCard(
                  icon: Icons.admin_panel_settings_outlined,
                  title: l10n.registerTypeChurchAdmin,
                  onTap: () =>
                      context.push(AppRoutes.registerNewChurchSuperAdmin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
