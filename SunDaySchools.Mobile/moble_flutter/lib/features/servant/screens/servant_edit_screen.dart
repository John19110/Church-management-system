import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/servant_models.dart';
import '../providers/servants_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../core/l10n/app_localizations.dart';

class ServantEditScreen extends ConsumerStatefulWidget {
  final int id;
  const ServantEditScreen({super.key, required this.id});

  @override
  ConsumerState<ServantEditScreen> createState() => _ServantEditScreenState();
}

class _ServantEditScreenState extends ConsumerState<ServantEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _joiningController = TextEditingController();
  final _birthController = TextEditingController();
  final _classroomController = TextEditingController();
  File? _image;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _joiningController.dispose();
    _birthController.dispose();
    _classroomController.dispose();
    super.dispose();
  }

  void _initFromServant(ServantReadDto servant) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = servant.name ?? '';
    _phoneController.text = servant.phoneNumber ?? '';
    _joiningController.text = servant.joiningDate ?? '';
    _birthController.text = servant.birthDate ?? '';
    _classroomController.text = servant.classrooms.isNotEmpty
        ? servant.classrooms.first.id.toString()
        : '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(servantsRepositoryProvider).update(
            widget.id,
            name: _nameController.text.trim().nullIfEmpty,
            phoneNumber: _phoneController.text.trim().nullIfEmpty,
            joiningDate: _joiningController.text.trim().nullIfEmpty,
            birthDate: _birthController.text.trim().nullIfEmpty,
            classroomId: int.tryParse(_classroomController.text.trim()),
            image: _image,
          );
      if (mounted) {
        showSuccessSnackbar(context, l10n.servantUpdatedSuccessfully);
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
    final servantAsync = ref.watch(servantDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editServant)),
      body: SafeArea(
        child: servantAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (servant) {
          _initFromServant(servant);
          return Form(
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
                          ? FileImage(_image!) as ImageProvider
                          : (servant.imageUrl != null
                              ? NetworkImage(servant.imageUrl!)
                              : null),
                      child: (_image == null && servant.imageUrl == null)
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
                ),
                const SizedBox(height: 12),
                AppDateField(
                    controller: _joiningController, label: l10n.joiningDate),
                const SizedBox(height: 12),
                AppDateField(
                    controller: _birthController, label: l10n.birthDate),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _classroomController,
                  label: l10n.classroomId,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        child: Text(l10n.save),
                      ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
