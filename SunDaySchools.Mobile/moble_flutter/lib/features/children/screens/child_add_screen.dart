import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/child_models.dart';
import '../providers/children_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';

class ChildAddScreen extends ConsumerStatefulWidget {
  const ChildAddScreen({super.key});

  @override
  ConsumerState<ChildAddScreen> createState() => _ChildAddScreenState();
}

class _ChildAddScreenState extends ConsumerState<ChildAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name1Controller = TextEditingController();
  final _name2Controller = TextEditingController();
  final _name3Controller = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _joiningController = TextEditingController();
  final _classroomController = TextEditingController();
  String? _gender;
  bool _loading = false;

  // Phone number pairs
  final List<TextEditingController> _phoneRelation = [];
  final List<TextEditingController> _phoneNumber = [];

  @override
  void dispose() {
    _name1Controller.dispose();
    _name2Controller.dispose();
    _name3Controller.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _joiningController.dispose();
    _classroomController.dispose();
    for (final c in _phoneRelation) c.dispose();
    for (final c in _phoneNumber) c.dispose();
    super.dispose();
  }

  void _addPhoneRow() {
    setState(() {
      _phoneRelation.add(TextEditingController());
      _phoneNumber.add(TextEditingController());
    });
  }

  void _removePhoneRow(int index) {
    setState(() {
      _phoneRelation[index].dispose();
      _phoneNumber[index].dispose();
      _phoneRelation.removeAt(index);
      _phoneNumber.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final phones = List.generate(
        _phoneRelation.length,
        (i) => ChildContactDto(
          relation: _phoneRelation[i].text.trim(),
          phoneNumber: _phoneNumber[i].text.trim(),
        ),
      );
      await ref.read(childrenRepositoryProvider).create(
            ChildAddDto(
              name1: _name1Controller.text.trim().nullIfEmpty,
              name2: _name2Controller.text.trim().nullIfEmpty,
              name3: _name3Controller.text.trim().nullIfEmpty,
              gender: _gender,
              address: _addressController.text.trim().nullIfEmpty,
              dateOfBirth: _dobController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              classroomId: int.tryParse(_classroomController.text.trim()),
              phoneNumbers: phones.isEmpty ? null : phones,
            ),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Child added successfully');
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
      appBar: AppBar(title: const Text('Add Child')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _name1Controller,
              label: 'First Name',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'First name is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _name2Controller, label: 'Middle Name'),
            const SizedBox(height: 12),
            AppTextField(controller: _name3Controller, label: 'Last Name'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _addressController,
              label: 'Address',
            ),
            const SizedBox(height: 12),
            AppDateField(
              controller: _dobController,
              label: 'Date of Birth',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Date of birth is required' : null,
            ),
            const SizedBox(height: 12),
            AppDateField(
              controller: _joiningController,
              label: 'Joining Date',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Joining date is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _classroomController,
              label: 'Classroom ID',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Phone Numbers',
                    style: Theme.of(context).textTheme.titleSmall),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2B6CB0)),
                  onPressed: _addPhoneRow,
                ),
              ],
            ),
            ..._phoneRelation.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _phoneRelation[i],
                        label: 'Relation',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextField(
                        controller: _phoneNumber[i],
                        label: 'Phone',
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removePhoneRow(i),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Add Child'),
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
