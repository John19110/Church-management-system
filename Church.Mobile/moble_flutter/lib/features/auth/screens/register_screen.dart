import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_role_utils.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';

enum _RegisterType { servant, churchAdmin, meetingAdmin }

/// Which registration form to present. Chosen by the registration entry /
/// new-church role screens, so the form no longer shows a type dropdown.
enum RegisterFormMode {
  existingChurchMember,
  newChurchMeetingAdmin,
  newChurchSuperAdmin,
}

class RegisterScreen extends ConsumerStatefulWidget {
  final RegisterFormMode mode;

  const RegisterScreen({
    super.key,
    this.mode = RegisterFormMode.existingChurchMember,
  });

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Existing-church member controllers
  final _churchIdController = TextEditingController();
  final _requestedMeetingController = TextEditingController();
  final _meetingAdminPhoneController = TextEditingController();

  // Requested role for existing-church member registration.
  String _requestedRole = 'Servant';

  // Church/Meeting admin controllers
  final _churchNameController = TextEditingController();
  final _meetingNameController = TextEditingController();
  final _weeklyAppointmentController = TextEditingController();
  String _selectedMeetingDay = 'Saturday';
  TimeOfDay? _selectedWeeklyTime;

  // Optional controllers
  final _birthController = TextEditingController();
  final _joiningController = TextEditingController();

  File? _image;
  _RegisterType _selectedType = _RegisterType.servant;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.text = 'TestPassword@12345';
    _confirmPasswordController.text = 'TestPassword@12345';
    _selectedType = switch (widget.mode) {
      RegisterFormMode.existingChurchMember => _RegisterType.servant,
      RegisterFormMode.newChurchMeetingAdmin => _RegisterType.meetingAdmin,
      RegisterFormMode.newChurchSuperAdmin => _RegisterType.churchAdmin,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _churchIdController.dispose();
    _requestedMeetingController.dispose();
    _meetingAdminPhoneController.dispose();
    _churchNameController.dispose();
    _meetingNameController.dispose();
    _weeklyAppointmentController.dispose();
    _birthController.dispose();
    _joiningController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_selectedType == _RegisterType.meetingAdmin) {
      if (_selectedWeeklyTime == null) {
        showErrorSnackbar(context, l10n.weeklyAppointmentRequired);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      AuthFlowResult result;
      switch (_selectedType) {
        case _RegisterType.servant:
          result = await ref.read(authRepositoryProvider).registerServant(
            RegisterServantDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchPublicId: _churchIdController.text.trim(),
              requestedMeetingName: _requestedRole == 'ChurchAdmin'
                  ? ''
                  : _requestedMeetingController.text.trim(),
              requestedRole: _requestedRole,
              meetingAdminPhoneNumber: _requestedRole == 'Servant'
                  ? _meetingAdminPhoneController.text.trim().nullIfEmpty
                  : null,
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;

        case _RegisterType.churchAdmin:
          result = await ref.read(authRepositoryProvider)
              .registerChurchSuperAdmin(
            RegisterChurchSuperAdminDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchName: _churchNameController.text.trim(),
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;

        case _RegisterType.meetingAdmin:
          result = await ref.read(authRepositoryProvider).registerMeetingAdmin(
            RegisterMeetingAdminDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchName: _churchNameController.text.trim(),
              meetingName: _meetingNameController.text.trim(),
              weeklyAppointment: _selectedWeeklyTime!,
              dayOfWeek: _selectedMeetingDay,
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;
      }

      if (result.requiresPhoneVerification) {
        if (mounted) {
          // Phone verification disabled — account created; send user to login.
          // final phone = result.phoneNumber ?? _phoneController.text.trim();
          // showSuccessSnackbar(
          //   context,
          //   result.message ?? 'Check WhatsApp for your verification code.',
          // );
          // context.go(
          //   '${AppRoutes.verifyPhone}?phone=${Uri.encodeComponent(phone)}',
          // );
          showSuccessSnackbar(
            context,
            result.message ?? l10n.registrationSuccessfulPleaseSignIn,
          );
          context.go(AppRoutes.login);
        }
        return;
      }

      final token = result.token;
      if (token == null || token.isEmpty) {
        throw Exception('Registration did not return a token.');
      }

      final role = AuthRoleUtils.extractPrimaryRole(token);

      ref.read(authSessionEpochProvider.notifier).state++;
      ref.read(authStateProvider.notifier).state = true;

      if (mounted) {
        context.go(AuthRoleUtils.routeForRole(role));
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      // Names can repeat; phone must be unique (login identifier).
      if (e is ApiException) {
        final msg = e.message.toLowerCase();
        final isPhoneDuplicate = (e.statusCode == 409 || e.statusCode == 400) &&
            (msg.contains('phone') ||
                msg.contains('phonenumber') ||
                msg.contains('mobile')) &&
            (msg.contains('exist') ||
                msg.contains('already') ||
                msg.contains('duplicate') ||
                msg.contains('taken') ||
                msg.contains('use'));

        if (isPhoneDuplicate) {
          showErrorSnackbar(context, l10n.phoneAlreadyUsed);
          return;
        }
      }

      showErrorSnackbar(context, userFriendlyMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formTitle(AppLocalizations l10n) {
    switch (widget.mode) {
      case RegisterFormMode.existingChurchMember:
        return l10n.joinExistingChurchTitle;
      case RegisterFormMode.newChurchMeetingAdmin:
        return l10n.registerTypeMeetingAdmin;
      case RegisterFormMode.newChurchSuperAdmin:
        return l10n.registerTypeChurchAdmin;
    }
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: AppColors.primary,
          backgroundImage: _image != null ? FileImage(_image!) : null,
          child: _image == null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 28, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                l10n.tapToSelectImage,
                style:
                const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          )
              : null,
        ),
      ),
    );
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
                Text(
                  _formTitle(l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // ✅ Image picker FIRST
                _buildImagePicker(l10n),

                const SizedBox(height: 16),

                // Shared fields
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
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
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
                    if (v == null || v.isEmpty) {
                      return l10n.pleaseConfirmPassword;
                    }
                    if (v != _passwordController.text) {
                      return l10n.passwordsDoNotMatch;
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),

                const SizedBox(height: 16),

                AppDateField(
                  controller: _birthController,
                  label: l10n.birthDate,
                ),
                const SizedBox(height: 16),
                AppDateField(
                  controller: _joiningController,
                  label: l10n.joiningDate,
                ),
                const SizedBox(height: 16),

                if (_selectedType == _RegisterType.servant) ...[
                  AppTextField(
                    controller: _churchIdController,
                    label: l10n.churchOrMeetingIdLabel,
                    hint: l10n.enterChurchOrMeetingId,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.churchOrMeetingIdRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _requestedRole,
                    decoration: InputDecoration(labelText: l10n.requestedRoleLabel),
                    items: [
                      DropdownMenuItem(
                        value: 'Servant',
                        child: Text(l10n.registerTypeServant),
                      ),
                      DropdownMenuItem(
                        value: 'MeetingAdmin',
                        child: Text(l10n.registerTypeMeetingAdmin),
                      ),
                      DropdownMenuItem(
                        value: 'ChurchAdmin',
                        child: Text(l10n.registerTypeChurchAdmin),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _requestedRole = v);
                    },
                  ),
                  // Church Admin manages the whole church, so no meeting is requested.
                  if (_requestedRole != 'ChurchAdmin') ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _requestedMeetingController,
                      label: l10n.requestedMeetingName,
                      hint: l10n.enterRequestedMeetingName,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.requestedMeetingNameChurchIdHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                  if (_requestedRole == 'Servant') ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _meetingAdminPhoneController,
                      label: l10n.meetingAdminPhone,
                      hint: l10n.enterMeetingAdminPhone,
                      keyboardType: TextInputType.phone,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.meetingAdminPhoneChurchIdHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],

                if (_selectedType == _RegisterType.churchAdmin) ...[
                  AppTextField(
                    controller: _churchNameController,
                    label: l10n.churchName,
                    hint: l10n.enterChurchName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.churchNameRequired
                            : null,
                  ),
                ],

                if (_selectedType == _RegisterType.meetingAdmin) ...[
                  AppTextField(
                    controller: _churchNameController,
                    label: l10n.churchName,
                    hint: l10n.enterChurchName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.churchNameRequired
                            : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _meetingNameController,
                    label: l10n.meetingName,
                    hint: l10n.enterMeetingName,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? l10n.meetingNameRequired
                            : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMeetingDay,
                    decoration: InputDecoration(
                      labelText: l10n.meetingDayOfWeek,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'Saturday',
                        child: Text(l10n.weekdaySaturday),
                      ),
                      DropdownMenuItem(
                        value: 'Sunday',
                        child: Text(l10n.weekdaySunday),
                      ),
                      DropdownMenuItem(
                        value: 'Monday',
                        child: Text(l10n.weekdayMonday),
                      ),
                      DropdownMenuItem(
                        value: 'Tuesday',
                        child: Text(l10n.weekdayTuesday),
                      ),
                      DropdownMenuItem(
                        value: 'Wednesday',
                        child: Text(l10n.weekdayWednesday),
                      ),
                      DropdownMenuItem(
                        value: 'Thursday',
                        child: Text(l10n.weekdayThursday),
                      ),
                      DropdownMenuItem(
                        value: 'Friday',
                        child: Text(l10n.weekdayFriday),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedMeetingDay = v!),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.required
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _weeklyAppointmentController,
                    label: l10n.weeklyAppointment,
                    hint: l10n.weeklyAppointmentHint,
                    readOnly: true,
                    onTap: () async {
                      if (_loading) return;
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _selectedWeeklyTime ?? TimeOfDay.now(),
                      );
                      if (!mounted) return;
                      if (picked == null) return;
                      setState(() {
                        _selectedWeeklyTime = picked;
                        _weeklyAppointmentController.text = picked.format(context);
                      });
                    },
                    validator: (_) =>
                        _selectedWeeklyTime == null ? l10n.weeklyAppointmentRequired : null,
                  ),
                ],

                const SizedBox(height: 24),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _register,
                  child: Text(l10n.register),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}