import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/endpoint_select_fields.dart';
import '../providers/servants_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthController = TextEditingController();
  final _joiningController = TextEditingController();
  final _spiritualBirthController = TextEditingController();
  final _churchIdController = TextEditingController();
  int? _meetingId;
  List<int> _classroomIds = [];
  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _joiningController.dispose();
    _spiritualBirthController.dispose();
    _churchIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    if (_loading) return;
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked == null) return;
    controller.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final churchId = _churchIdController.text.trim().isEmpty
          ? null
          : int.tryParse(_churchIdController.text.trim());

      await ref.read(servantsRepositoryProvider).updateProfile(
            name: _nameController.text.trim().isEmpty
                ? null
                : _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            birthDate: _birthController.text.trim().nullIfEmpty,
            joiningDate: _joiningController.text.trim().nullIfEmpty,
            spiritualBirthDate: _spiritualBirthController.text.trim().nullIfEmpty,
            churchId: churchId,
            meetingId: _meetingId,
            classroomIds: List<int>.from(_classroomIds),
            image: _image,
          );

      if (!mounted) return;
      showSuccessSnackbar(context, AppLocalizations.of(context).profileUpdated);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(servantProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfile)),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.failedToLoadProfile} $e')),
        data: (p) {
          // Pre-fill once when controllers are empty (first build).
          if (_nameController.text.isEmpty && _phoneController.text.isEmpty) {
            _nameController.text = p.name ?? '';
            _phoneController.text = p.phoneNumber ?? '';
            _birthController.text = p.birthDate ?? '';
            _joiningController.text = p.joiningDate ?? '';
            _spiritualBirthController.text = p.spiritualBirthDate ?? '';
            _churchIdController.text = p.church?.id.toString() ?? '';
            _meetingId = p.meeting?.id;
            _classroomIds = p.classrooms.map((c) => c.id).toList();
          }

          return SafeArea(
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
                        backgroundImage: _image != null
                            ? FileImage(_image!)
                            : (p.imageUrl != null
                                ? NetworkImage(p.imageUrl!) as ImageProvider
                                : null),
                        child: (_image == null && p.imageUrl == null)
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
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _phoneController,
                    label: l10n.phoneNumber,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _churchIdController,
                    label: l10n.churchIdLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  EndpointSelectDropdown(
                    endpoint: SelectionEndpoints.meetings,
                    label: l10n.meetingLabel,
                    hintText: l10n.selectMeeting,
                    value: _meetingId,
                    enabled: !_loading,
                    onChanged: (v) => setState(() => _meetingId = v),
                  ),
                  const SizedBox(height: 12),
                  EndpointMultiSelectField(
                    endpoint: SelectionEndpoints.classrooms,
                    label: l10n.classroomsLabel,
                    hintText: l10n.selectClassrooms,
                    selectedIds: _classroomIds,
                    onChanged: (ids) => setState(() => _classroomIds = ids),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _birthController,
                    label: l10n.birthDate,
                    readOnly: true,
                    onTap: () => _pickDate(_birthController),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _joiningController,
                    label: l10n.joiningDate,
                    readOnly: true,
                    onTap: () => _pickDate(_joiningController),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _spiritualBirthController,
                    label: l10n.spiritualDateOfBirth,
                    readOnly: true,
                    onTap: () => _pickDate(_spiritualBirthController),
                  ),
                  const SizedBox(height: 20),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _save,
                          child: Text(l10n.saveLabel),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => trim().isEmpty ? null : trim();
}

