import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/shared_preferences_provider.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../providers/auth_providers.dart';
import '../utils/account_data_cleaner.dart';

/// Destructive account action shown at the bottom of the Profile/Settings page.
class DeleteAccountSection extends ConsumerStatefulWidget {
  const DeleteAccountSection({super.key});

  @override
  ConsumerState<DeleteAccountSection> createState() =>
      _DeleteAccountSectionState();
}

class _DeleteAccountSectionState extends ConsumerState<DeleteAccountSection> {
  bool _deleting = false;

  Future<void> _requestDeletion() async {
    final l10n = AppLocalizations.of(context);
    final confirmed =
        await showDialog<bool>(
          context: context,
          barrierDismissible: !_deleting,
          builder: (dialogContext) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 40,
            ),
            title: Text(l10n.deleteAccountTitle),
            content: Text(l10n.deleteAccountWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(l10n.deleteAccount),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      await AccountDataCleaner.clear(ref.read(sharedPreferencesProvider));

      ref.read(authStateProvider.notifier).state = false;
      ref.read(authSessionEpochProvider.notifier).state++;

      if (!mounted) return;
      showSuccessSnackbar(context, l10n.deleteAccountSuccess);
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      final message =
          error is ApiException &&
              (error.statusCode == null || error.statusCode! >= 500)
          ? l10n.deleteAccountFailure
          : userFriendlyMessage(error, l10n);
      showErrorSnackbar(
        context,
        message.trim().isEmpty ? l10n.deleteAccountFailure : message,
      );
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 32),
        Text(
          l10n.deleteAccountWarning,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger),
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: _deleting ? null : _requestDeletion,
          icon: _deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.danger,
                  ),
                )
              : const Icon(Icons.delete_forever_outlined),
          label: Text(_deleting ? l10n.deletingAccount : l10n.deleteAccount),
        ),
      ],
    );
  }
}
