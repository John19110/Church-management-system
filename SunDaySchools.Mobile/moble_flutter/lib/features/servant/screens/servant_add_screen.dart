import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../../../core/l10n/app_localizations.dart';

class ServantAddScreen extends ConsumerStatefulWidget {
  const ServantAddScreen({super.key});

  @override
  ConsumerState<ServantAddScreen> createState() => _ServantAddScreenState();
}

class _ServantAddScreenState extends ConsumerState<ServantAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _joiningController = TextEditingController();
  final _birthController = TextEditingController();
  List<int> _selectedClassroomIds = [];
  File? _image;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _joiningController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClassroomIds.isEmpty) {
      final l10n = AppLocalizations.of(context);
      if (mounted) {
        showErrorSnackbar(context, '${l10n.required}: ${l10n.classroomId}');
      }
      return;
    }
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(servantsRepositoryProvider).create(
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            joiningDate: _joiningController.text.trim().nullIfEmpty,
            birthDate: _birthController.text.trim().nullIfEmpty,
            classroomsIds: List<int>.from(_selectedClassroomIds),
            image: _image,
          );
      if (mounted) {
        showSuccessSnackbar(context, l10n.servantAddedSuccessfully);
        context.pop();
      }
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
      appBar: AppBar(title: Text(l10n.addServant)),
      body: SafeArea(
        child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFFED8936),
                  backgroundImage:
                      _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.camera_alt,
                          size: 36, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _nameController,
              label: l10n.name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneController,
              label: l10n.phoneNumber,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.phoneRequired : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              label: l10n.password,
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
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmPasswordController,
              label: l10n.confirmPassword,
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v == null || v.isEmpty) return l10n.pleaseConfirmPassword;
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
            const SizedBox(height: 12),
            AppDateField(controller: _joiningController, label: l10n.joiningDate),
            const SizedBox(height: 12),
            AppDateField(controller: _birthController, label: l10n.birthDate),
            const SizedBox(height: 12),
            EndpointMultiSelectField(
              endpoint: SelectionEndpoints.classrooms,
              label: l10n.classroomId,
              hintText: l10n.classroomId,
              selectedIds: _selectedClassroomIds,
              onChanged: (ids) => setState(() => _selectedClassroomIds = ids),
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: Text(l10n.addServant),
                  ),
          ],
        ),
      ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
