import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _churchIdController = TextEditingController();
  final _meetingIdController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _churchIdController.dispose();
    _meetingIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(authRepositoryProvider).registerServant(
            RegisterServantDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchId: int.parse(_churchIdController.text.trim()),
              meetingId: int.parse(_meetingIdController.text.trim()),
            ),
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccount)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _nameController,
                  label: l10n.fullName,
                  hint: l10n.enterName,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  label: l10n.phoneNumber,
                  hint: l10n.enterPhoneNumber,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l10n.phoneRequired : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  label: l10n.password,
                  hint: l10n.enterPassword,
                  obscureText: _obscurePassword,
                  validator: (v) =>
                      (v == null || v.length < 6) ? l10n.passwordTooShort : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: l10n.confirmPassword,
                  hint: l10n.enterConfirmPassword,
                  obscureText: _obscureConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.pleaseConfirmPassword;
                    if (v != _passwordController.text) return l10n.passwordsDoNotMatch;
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _churchIdController,
                  label: l10n.churchId,
                  hint: l10n.enterChurchId,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.churchIdRequired;
                    if (int.tryParse(v.trim()) == null) return l10n.churchIdRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _meetingIdController,
                  label: l10n.meetingId,
                  hint: l10n.enterMeetingId,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l10n.meetingIdRequired;
                    if (int.tryParse(v.trim()) == null) return l10n.meetingIdRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text(l10n.register),
                      ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
