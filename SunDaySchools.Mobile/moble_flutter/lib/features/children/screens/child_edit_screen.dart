import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/child_models.dart';
import '../providers/children_providers.dart';
import '../../../shared/widgets/app_form_fields.dart';
import '../../../shared/widgets/common_widgets.dart';

class ChildEditScreen extends ConsumerStatefulWidget {
  final int id;
  const ChildEditScreen({super.key, required this.id});

  @override
  ConsumerState<ChildEditScreen> createState() => _ChildEditScreenState();
}

class _ChildEditScreenState extends ConsumerState<ChildEditScreen> {
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
  bool _initialized = false;

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

  void _initFromChild(ChildReadDto child) {
    if (_initialized) return;
    _initialized = true;
    // fullName may be "name1 name2 name3"; we just populate name1
    _name1Controller.text = child.fullName ?? '';
    _addressController.text = child.address ?? '';
    _dobController.text = child.dateOfBirth ?? '';
    _joiningController.text = child.joiningDate ?? '';
    _classroomController.text = child.classroomId?.toString() ?? '';
    _gender = child.gender;
    if (child.phoneNumbers != null) {
      for (final p in child.phoneNumbers!) {
        _phoneRelation.add(TextEditingController(text: p.relation ?? ''));
        _phoneNumber.add(TextEditingController(text: p.phoneNumber ?? ''));
      }
    }
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
      await ref.read(childrenRepositoryProvider).update(
            widget.id,
            ChildUpdateDto(
              id: widget.id,
              name1: _name1Controller.text.trim().nullIfEmpty,
              gender: _gender,
              address: _addressController.text.trim().nullIfEmpty,
              dateOfBirth: _dobController.text.trim().nullIfEmpty,
              joiningDate: _joiningController.text.trim().nullIfEmpty,
              classroomId: int.tryParse(_classroomController.text.trim()),
              phoneNumbers: phones.isEmpty ? null : phones,
            ),
          );
      if (mounted) {
        showSuccessSnackbar(context, 'Child updated successfully');
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
    final childAsync = ref.watch(childDetailProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Child')),
      body: childAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => AppErrorWidget(message: e.toString()),
        data: (child) {
          _initFromChild(child);
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppTextField(
                  controller: _name1Controller,
                  label: 'Full Name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
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
                ),
                const SizedBox(height: 12),
                AppDateField(
                  controller: _joiningController,
                  label: 'Joining Date',
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
                      icon: const Icon(Icons.add_circle,
                          color: Color(0xFF2B6CB0)),
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
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
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
                        child: const Text('Save Changes'),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

extension _StringExt on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
