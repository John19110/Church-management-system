import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_router.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_pin_input.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const ResetPasswordScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpKey = GlobalKey<OtpPinInputState>();
  String _otpCode = '';
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
    _passwordController.dispose();
    _confirmController.dispose();
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
          .forgotPassword(PhoneOtpDto(phoneNumber: widget.phoneNumber));
      _startTimer(cooldown);
      if (mounted) showSuccessSnackbar(context, 'Reset code sent.');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_otpCode.length != 6) {
      showErrorSnackbar(context, 'Enter the 6-digit code.');
      return;
    }
    if (_passwordController.text.length < 6) {
      showErrorSnackbar(context, 'Password must be at least 6 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      showErrorSnackbar(context, 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            ResetPasswordDto(
              phoneNumber: widget.phoneNumber,
              code: _otpCode,
              newPassword: _passwordController.text,
            ),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Password updated. Please sign in.');
        context.go(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Reset code sent to ${widget.phoneNumber} via WhatsApp.'),
            const SizedBox(height: 16),
            OtpPinInput(
              key: _otpKey,
              enabled: !_loading,
              onChanged: (v) => _otpCode = v,
              onCompleted: (v) => _otpCode = v,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _secondsLeft > 0 || _loading ? null : _resend,
              child: Text(
                _secondsLeft > 0
                    ? 'Resend code in $_secondsLeft s'
                    : 'Resend code',
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'New password',
              obscureText: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmController,
              label: 'Confirm password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : FilledButton(
                    onPressed: _submit,
                    child: const Text('Reset password'),
                  ),
          ],
        ),
      ),
    );
  }
}
