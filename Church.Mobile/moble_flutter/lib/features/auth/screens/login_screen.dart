import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_role_utils.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/error/app_exception.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = "TestPassword@12345";
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final result = await ref.read(authRepositoryProvider).login(
        LoginDto(
          phoneNumber: _phoneController.text.trim(),
          password: _passwordController.text,
        ),
      );

      // Phone verification disabled
      // if (result.requiresPhoneVerification) {
      //   if (mounted) {
      //     final phone = result.phoneNumber ?? _phoneController.text.trim();
      //     context.go(
      //       '${AppRoutes.verifyPhone}?phone=${Uri.encodeComponent(phone)}',
      //     );
      //   }
      //   return;
      // }

      final token = result.token;
      if (token == null || token.isEmpty) {
        throw Exception('Login did not return a token.');
      }

      final role = AuthRoleUtils.extractPrimaryRole(token);

      ref.read(authSessionEpochProvider.notifier).state++;
      ref.read(authStateProvider.notifier).state = true;

      if (mounted) context.go(AuthRoleUtils.routeForRole(role));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        // Approval gate: show the friendly localized message for pending/rejected.
        if (e is ApiException && e.errorCode == 'ACCOUNT_PENDING') {
          showErrorSnackbar(context, l10n.accountPendingApproval);
          return;
        }
        if (e is ApiException && e.errorCode == 'ACCOUNT_REJECTED') {
          showErrorSnackbar(context, l10n.accountRejected);
          return;
        }
        showErrorSnackbar(context, userFriendlyMessage(e, l10n));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final palette = context.palette;

    final isDark = themeMode == ThemeMode.dark;
    final isArabic = locale.languageCode == 'ar';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header bar: language + theme toggles (logic preserved).
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(localeProvider.notifier).toggle(),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundImage: AssetImage(
                        isArabic ? 'assets/flags/uk.png' : 'assets/flags/eg.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    tooltip: isDark ? l10n.lightMode : l10n.darkMode,
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    onPressed: () =>
                        ref.read(themeModeProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _brandMark(theme),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            l10n.churchBrand,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n.managementSystem,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),
                          AppTextField(
                            controller: _phoneController,
                            label: l10n.phoneNumber,
                            hint: l10n.enterPhoneNumber,
                            keyboardType: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? l10n.phoneRequired
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _passwordController,
                            label: l10n.password,
                            hint: l10n.enterPassword,
                            obscureText: _obscurePassword,
                            validator: (v) => (v == null || v.isEmpty)
                                ? l10n.passwordRequired
                                : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: palette.textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          AppButton(
                            label: l10n.login,
                            loading: _loading,
                            onPressed: _login,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: Text(l10n.dontHaveAccount),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandMark(ThemeData theme) {
    return Center(
      child: Container(
        height: 96,
        width: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: AppRadius.xlAll,
        ),
        child: Icon(
          Icons.church_rounded,
          size: 52,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}