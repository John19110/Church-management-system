import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';

class ServantAddScreen extends ConsumerStatefulWidget {
  const ServantAddScreen({super.key});

  @override
  ConsumerState<ServantAddScreen> createState() => _ServantAddScreenState();
}

class _ServantAddScreenState extends ConsumerState<ServantAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userIdController = TextEditingController();
  final _joiningController = TextEditingController();
  final _birthController = TextEditingController();
  final _classroomController = TextEditingController();
  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _userIdController.dispose();
    _joiningController.dispose();
    _birthController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(servantsRepositoryProvider).create(
            name: _nameController.text.trim(),
            applicationUserId: _userIdController.text.trim(),
            phoneNumber: _phoneController.text.trim().nullIfEmpty,
            joiningDate: _joiningController.text.trim().nullIfEmpty,
            birthDate: _birthController.text.trim().nullIfEmpty,
            classroomId: int.tryParse(_classroomController.text.trim()),
            image: _image,
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Servant added successfully');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Add Servant')),
      body: Form(
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
              label: 'Name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _userIdController,
              label: 'Application User ID',
              hint: 'Required — user UUID from auth system',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'User ID is required' : null,
            ),
            const SizedBox(height: 12),
            AppDateField(controller: _joiningController, label: 'Joining Date'),
            const SizedBox(height: 12),
            AppDateField(controller: _birthController, label: 'Birth Date'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _classroomController,
              label: 'Classroom ID',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add Servant'),
                  ),
          ],
        ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
