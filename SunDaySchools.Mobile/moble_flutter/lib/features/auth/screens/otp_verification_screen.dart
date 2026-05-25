import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_pin_input.dart';

/// Verifies WhatsApp OTP after registration or resend from phone entry.
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpKey = GlobalKey<OtpPinInputState>();
  bool _loading = false;
  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    setState(() => _loading = true);
    try {
      final cooldown = await ref
          .read(authRepositoryProvider)
          .sendWhatsAppOtp(PhoneOtpDto(phoneNumber: widget.phoneNumber));
      _startTimer(cooldown);
      if (mounted) {
        showSuccessSnackbar(context, 'Verification code sent via WhatsApp.');
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, userFriendlyMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify(String code) async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyWhatsAppOtp(
            VerifyOtpDto(phoneNumber: widget.phoneNumber, code: code),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Phone verified. You can sign in now.');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, userFriendlyMessage(e));
        _otpKey.currentState?.clear();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify phone')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber} on WhatsApp.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OtpPinInput(
                key: _otpKey,
                enabled: !_loading,
                onCompleted: _verify,
              ),
              const SizedBox(height: 24),
              if (_loading) const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _secondsLeft > 0 || _loading ? null : _resend,
                child: Text(
                  _secondsLeft > 0
                      ? 'Resend code in $_secondsLeft s'
                      : 'Resend code',
                ),
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: _loading ? null : () => context.go(AppRoutes.login),
                child: Text(l10n.login),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
