import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_models.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_role_utils.dart';
import '../../classroom/providers/classroom_providers.dart';
import '../../meeting/providers/meeting_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';

enum _RegisterType { servant, churchAdmin, meetingAdmin }

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

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

  // Servant-specific controllers
  final _churchIdController = TextEditingController();
  final _meetingIdController = TextEditingController();

  // Church/Meeting admin controllers
  final _churchNameController = TextEditingController();
  final _meetingNameController = TextEditingController();
  final _weeklyAppointmentController = TextEditingController();

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
    _passwordController.text = 'John6464@asu';
    _confirmPasswordController.text = 'John6464@asu';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _churchIdController.dispose();
    _meetingIdController.dispose();
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
    DateTime? parsedWeekly;
    if (_selectedType == _RegisterType.meetingAdmin) {
      parsedWeekly = DateTime.tryParse(_weeklyAppointmentController.text.trim());
      if (parsedWeekly == null) {
        showErrorSnackbar(context, l10n.invalidWeeklyAppointment);
        return;
      }
    }
    setState(() => _loading = true);
    try {
      String? token;
      switch (_selectedType) {
        case _RegisterType.servant:
          token = await ref.read(authRepositoryProvider).registerServant(
            RegisterServantDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchId: int.parse(_churchIdController.text.trim()),
              meetingId: int.parse(_meetingIdController.text.trim()),
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;

        case _RegisterType.churchAdmin:
          token = await ref.read(authRepositoryProvider)
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
          token = await ref.read(authRepositoryProvider).registerMeetingAdmin(
            RegisterMeetingAdminDto(
              name: _nameController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              churchName: _churchNameController.text.trim(),
              meetingName: _meetingNameController.text.trim(),
              weeklyAppointment: parsedWeekly!,
              birthDate: _birthController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              image: _image,
            ),
          );
          break;
      }

      final role =
          token != null ? AuthRoleUtils.extractPrimaryRole(token) : null;

      if (role == 'superadmin') {
        await ref.read(meetingRepositoryProvider).getVisibleMeetings();
      } else if (role == 'admin' || role == 'servant') {
        await ref.read(classroomRepositoryProvider).getVisible();
      }

      ref.read(authSessionEpochProvider.notifier).state++;
      ref.read(authStateProvider.notifier).state = true;

      if (mounted) {
        context.go(
          role == null ? '/dashboard' : AuthRoleUtils.routeForRole(role),
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImagePicker(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _pickImage,
      child: Center(
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFED8936),
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
                  l10n.selectRegistrationType,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),

                DropdownButtonFormField<_RegisterType>(
                  value: _selectedType,
                  items: [
                    DropdownMenuItem(
                      value: _RegisterType.servant,
                      child: Text(l10n.registerTypeServant),
                    ),
                    DropdownMenuItem(
                      value: _RegisterType.churchAdmin,
                      child: Text(l10n.registerTypeChurchAdmin),
                    ),
                    DropdownMenuItem(
                      value: _RegisterType.meetingAdmin,
                      child: Text(l10n.registerTypeMeetingAdmin),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedType = v;
                        _image = null;
                      });
                    }
                  },
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
                    label: l10n.churchId,
                    hint: l10n.enterChurchId,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.churchIdRequired;
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return l10n.required;
                      }
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
                      if (v == null || v.trim().isEmpty) {
                        return l10n.meetingIdRequired;
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return l10n.required;
                      }
                      return null;
                    },
                  ),
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
                  AppTextField(
                    controller: _weeklyAppointmentController,
                    label: l10n.weeklyAppointment,
                    hint: l10n.weeklyAppointmentHint,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.weeklyAppointmentRequired;
                      }
                      if (DateTime.tryParse(v.trim()) == null) {
                        return l10n.invalidWeeklyAppointment;
                      }
                      return null;
                    },
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