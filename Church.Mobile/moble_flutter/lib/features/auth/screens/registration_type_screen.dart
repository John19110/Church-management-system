import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../shared/widgets/app_form_shell.dart';
import '../utils/registration_navigation.dart';
import '../widgets/registration_choice_card.dart';

/// Registration entry: "Does your church already exist in the application?"
class RegistrationTypeScreen extends StatelessWidget {
  const RegistrationTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return registrationBackScope(
      context: context,
      fallbackRoute: AppRoutes.login,
      child: Scaffold(
        appBar: registrationAppBar(
          context: context,
          title: l10n.createAccount,
          fallbackRoute: AppRoutes.login,
        ),
        body: SafeArea(
          child: AppFormScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.churchExistsQuestion,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                RegistrationChoiceCard(
                  icon: Icons.check_circle_outline,
                  title: l10n.churchExistsYes,
                  onTap: () => context.push(AppRoutes.registerExistingChurch),
                ),
                const SizedBox(height: AppSpacing.md),
                RegistrationChoiceCard(
                  icon: Icons.add_business_outlined,
                  title: l10n.churchExistsNo,
                  onTap: () => context.push(AppRoutes.registerNewChurch),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
